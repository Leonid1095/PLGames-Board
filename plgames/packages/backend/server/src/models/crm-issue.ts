import { Injectable } from '@nestjs/common';
import type { CrmIssue, IssueStatus as IssueStatusType, Prisma } from '@prisma/client';
import pkg from '@prisma/client';
const { IssueStatus } = pkg;

import { BaseModel } from './base';

type CreateIssueInput = Prisma.CrmIssueUncheckedCreateInput;
type UpdateIssueInput = Prisma.CrmIssueUncheckedUpdateInput;

@Injectable()
export class CrmIssueModel extends BaseModel {
  async get(id: string): Promise<CrmIssue | null> {
    return this.db.crmIssue.findUnique({
      where: { id },
      include: {
        project: true,
        assignee: true,
        reporter: true,
        sprint: true,
        comments: {
          include: { author: true },
          orderBy: { createdAt: 'asc' },
        },
        timeLogs: {
          include: { user: true },
          orderBy: { loggedAt: 'desc' },
        },
      },
    });
  }

  async getByProject(projectId: string, filters?: {
    status?: IssueStatusType;
    assigneeId?: string;
    sprintId?: string;
  }): Promise<CrmIssue[]> {
    const where: Prisma.CrmIssueWhereInput = { projectId };

    if (filters?.status) {
      where.status = filters.status;
    }
    if (filters?.assigneeId) {
      where.assigneeId = filters.assigneeId;
    }
    if (filters?.sprintId) {
      where.sprintId = filters.sprintId;
    }

    return this.db.crmIssue.findMany({
      where,
      include: {
        assignee: true,
        reporter: true,
        sprint: true,
        _count: {
          select: { comments: true, timeLogs: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async create(data: CreateIssueInput): Promise<CrmIssue> {
    const issue = await this.db.crmIssue.create({
      data,
      include: {
        project: true,
        assignee: true,
        reporter: true,
      },
    });

    this.logger.debug(`CRM Issue [${issue.id}] created: ${issue.title}`);
    return issue;
  }

  async update(id: string, data: UpdateIssueInput): Promise<CrmIssue> {
    const issue = await this.db.crmIssue.update({
      where: { id },
      data,
      include: {
        project: true,
        assignee: true,
        reporter: true,
        sprint: true,
      },
    });

    this.logger.debug(`CRM Issue [${issue.id}] updated: ${issue.title}`);
    return issue;
  }

  async delete(id: string): Promise<CrmIssue> {
    const issue = await this.db.crmIssue.delete({
      where: { id },
    });

    this.logger.debug(`CRM Issue [${issue.id}] deleted: ${issue.title}`);
    return issue;
  }

  async countByProject(projectId: string): Promise<number> {
    return this.db.crmIssue.count({
      where: { projectId },
    });
  }

  async countByStatus(projectId: string): Promise<Record<IssueStatusType, number>> {
    const counts = await this.db.crmIssue.groupBy({
      by: ['status'],
      where: { projectId },
      _count: { status: true },
    });

    const result: Record<IssueStatusType, number> = {
      [IssueStatus.BACKLOG]: 0,
      [IssueStatus.TODO]: 0,
      [IssueStatus.IN_PROGRESS]: 0,
      [IssueStatus.IN_REVIEW]: 0,
      [IssueStatus.DONE]: 0,
      [IssueStatus.CANCELLED]: 0,
    };

    counts.forEach(count => {
      result[count.status] = count._count.status;
    });

    return result;
  }
}