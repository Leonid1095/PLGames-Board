import { Injectable, NotFoundException } from '@nestjs/common';
import type { IssueStatus } from '@prisma/client';

import { Models } from '../../models';
import type {
  CreateCommentInput,
  CreateIssueInput,
  CreateProjectInput,
  CreateSprintInput,
  CreateTimeLogInput,
  CrmCommentWithRelations,
  CrmIssueWithRelations,
  CrmProjectWithRelations,
  CrmSprintWithRelations,
  CrmTimeLogWithRelations,
  IssueFilters,
  UpdateCommentInput,
  UpdateIssueInput,
  UpdateProjectInput,
  UpdateSprintInput,
} from './types';

@Injectable()
export class CrmService {
  constructor(private readonly models: Models) {}

  private get projectModel() {
    return this.models.crmProject;
  }

  private get issueModel() {
    return this.models.crmIssue;
  }

  // ========== Projects ==========

  async getProject(id: string): Promise<CrmProjectWithRelations> {
    const project = await this.projectModel.get(id);
    if (!project) {
      throw new NotFoundException(`Project ${id} not found`);
    }
    return project as CrmProjectWithRelations;
  }

  async getProjectsByWorkspace(
    workspaceId: string
  ): Promise<CrmProjectWithRelations[]> {
    return this.projectModel.getByWorkspace(
      workspaceId
    ) as Promise<CrmProjectWithRelations[]>;
  }

  async createProject(input: CreateProjectInput): Promise<CrmProjectWithRelations> {
    return this.projectModel.create(input) as Promise<CrmProjectWithRelations>;
  }

  async updateProject(
    id: string,
    input: UpdateProjectInput
  ): Promise<CrmProjectWithRelations> {
    return this.projectModel.update(id, input) as Promise<CrmProjectWithRelations>;
  }

  async deleteProject(id: string): Promise<CrmProjectWithRelations> {
    return this.projectModel.delete(id) as Promise<CrmProjectWithRelations>;
  }

  // ========== Issues ==========

  async getIssue(id: string): Promise<CrmIssueWithRelations> {
    const issue = await this.issueModel.get(id);
    if (!issue) {
      throw new NotFoundException(`Issue ${id} not found`);
    }
    return issue as CrmIssueWithRelations;
  }

  async getIssuesByProject(
    projectId: string,
    filters?: IssueFilters
  ): Promise<CrmIssueWithRelations[]> {
    return this.issueModel.getByProject(
      projectId,
      filters as any
    ) as Promise<CrmIssueWithRelations[]>;
  }

  async createIssue(input: CreateIssueInput): Promise<CrmIssueWithRelations> {
    return this.issueModel.create(input as any) as Promise<CrmIssueWithRelations>;
  }

  async updateIssue(
    id: string,
    input: UpdateIssueInput
  ): Promise<CrmIssueWithRelations> {
    return this.issueModel.update(id, input as any) as Promise<CrmIssueWithRelations>;
  }

  async deleteIssue(id: string): Promise<CrmIssueWithRelations> {
    return this.issueModel.delete(id) as Promise<CrmIssueWithRelations>;
  }

  async getIssueStatusCount(
    projectId: string
  ): Promise<Record<IssueStatus, number>> {
    return this.issueModel.countByStatus(projectId);
  }

  // ========== Sprints ==========

  async getSprint(db: any, id: string): Promise<CrmSprintWithRelations> {
    const sprint = await db.crmSprint.findUnique({
      where: { id },
      include: {
        project: true,
        issues: {
          include: {
            assignee: true,
            reporter: true,
          },
        },
        _count: {
          select: { issues: true },
        },
      },
    });

    if (!sprint) {
      throw new NotFoundException(`Sprint ${id} not found`);
    }

    return sprint;
  }

  async getSprintsByProject(db: any, projectId: string): Promise<CrmSprintWithRelations[]> {
    return db.crmSprint.findMany({
      where: { projectId },
      include: {
        _count: {
          select: { issues: true },
        },
      },
      orderBy: { startDate: 'desc' },
    });
  }

  async createSprint(db: any, input: CreateSprintInput): Promise<CrmSprintWithRelations> {
    return db.crmSprint.create({
      data: input,
      include: {
        project: true,
      },
    });
  }

  async updateSprint(
    db: any,
    id: string,
    input: UpdateSprintInput
  ): Promise<CrmSprintWithRelations> {
    return db.crmSprint.update({
      where: { id },
      data: input,
      include: {
        project: true,
      },
    });
  }

  async deleteSprint(db: any, id: string): Promise<CrmSprintWithRelations> {
    return db.crmSprint.delete({
      where: { id },
    });
  }

  // ========== Comments ==========

  async getCommentsByIssue(db: any, issueId: string): Promise<CrmCommentWithRelations[]> {
    return db.crmComment.findMany({
      where: { issueId },
      include: {
        author: {
          select: {
            id: true,
            name: true,
            email: true,
            avatarUrl: true,
          },
        },
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  async createComment(db: any, input: CreateCommentInput): Promise<CrmCommentWithRelations> {
    return db.crmComment.create({
      data: input,
      include: {
        author: {
          select: {
            id: true,
            name: true,
            email: true,
            avatarUrl: true,
          },
        },
      },
    });
  }

  async updateComment(
    db: any,
    id: string,
    input: UpdateCommentInput
  ): Promise<CrmCommentWithRelations> {
    return db.crmComment.update({
      where: { id },
      data: input,
      include: {
        author: {
          select: {
            id: true,
            name: true,
            email: true,
            avatarUrl: true,
          },
        },
      },
    });
  }

  async deleteComment(db: any, id: string): Promise<CrmCommentWithRelations> {
    return db.crmComment.delete({
      where: { id },
    });
  }

  // ========== Time Logs ==========

  async getTimeLogsByIssue(db: any, issueId: string): Promise<CrmTimeLogWithRelations[]> {
    return db.crmTimeLog.findMany({
      where: { issueId },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            avatarUrl: true,
          },
        },
      },
      orderBy: { loggedAt: 'desc' },
    });
  }

  async createTimeLog(db: any, input: CreateTimeLogInput): Promise<CrmTimeLogWithRelations> {
    return db.crmTimeLog.create({
      data: input,
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            avatarUrl: true,
          },
        },
      },
    });
  }

  async deleteTimeLog(db: any, id: string): Promise<CrmTimeLogWithRelations> {
    return db.crmTimeLog.delete({
      where: { id },
    });
  }

  async getTotalTimeSpent(db: any, issueId: string): Promise<number> {
    const result = await db.crmTimeLog.aggregate({
      where: { issueId },
      _sum: {
        timeSpent: true,
      },
    });

    return result._sum.timeSpent || 0;
  }
}
