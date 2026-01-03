import { Injectable } from '@nestjs/common';
import type { CrmProject, Prisma } from '@prisma/client';

import { BaseModel } from './base';

type CreateProjectInput = Prisma.CrmProjectUncheckedCreateInput;
type UpdateProjectInput = Prisma.CrmProjectUncheckedUpdateInput;

@Injectable()
export class CrmProjectModel extends BaseModel {
  async get(id: string): Promise<CrmProject | null> {
    return this.db.crmProject.findUnique({
      where: { id },
      include: {
        workspace: true,
        lead: true,
      },
    });
  }

  async getByWorkspace(workspaceId: string): Promise<CrmProject[]> {
    return this.db.crmProject.findMany({
      where: { workspaceId },
      include: {
        lead: true,
        _count: {
          select: { issues: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async create(data: CreateProjectInput): Promise<CrmProject> {
    const project = await this.db.crmProject.create({
      data,
      include: {
        workspace: true,
        lead: true,
      },
    });

    this.logger.debug(`CRM Project [${project.id}] created: ${project.name}`);
    return project;
  }

  async update(id: string, data: UpdateProjectInput): Promise<CrmProject> {
    const project = await this.db.crmProject.update({
      where: { id },
      data,
      include: {
        workspace: true,
        lead: true,
      },
    });

    this.logger.debug(`CRM Project [${project.id}] updated: ${project.name}`);
    return project;
  }

  async delete(id: string): Promise<CrmProject> {
    const project = await this.db.crmProject.delete({
      where: { id },
    });

    this.logger.debug(`CRM Project [${project.id}] deleted: ${project.name}`);
    return project;
  }

  async countByWorkspace(workspaceId: string): Promise<number> {
    return this.db.crmProject.count({
      where: { workspaceId },
    });
  }
}