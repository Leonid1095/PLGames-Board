import { Args, Field, ID, InputType, Int, Mutation, ObjectType, Parent, Query, registerEnumType, ResolveField, Resolver } from '@nestjs/graphql';
import { ForbiddenException, Inject, UseGuards } from '@nestjs/common';
import type { IssueStatus, IssuePriority, IssueType, PrismaClient as PrismaClientType } from '@prisma/client';
import pkg from '@prisma/client';
const { IssueStatus: IssueStatusEnum, IssuePriority: IssuePriorityEnum, IssueType: IssueTypeEnum, PrismaClient } = pkg;

import { Auth, CurrentUser } from '../auth';
import { PermissionService } from '../permission';
import { CrmService } from './crm.service';
import type { CrmCommentWithRelations, CrmIssueWithRelations, CrmProjectWithRelations, CrmSprintWithRelations, CrmTimeLogWithRelations } from './types';

// Register enums
registerEnumType(IssueStatusEnum, { name: 'IssueStatus' });
registerEnumType(IssuePriorityEnum, { name: 'IssuePriority' });
registerEnumType(IssueTypeEnum, { name: 'IssueType' });

// ========== Object Types ==========

@ObjectType()
class UserInfo {
  @Field(() => ID)
  id!: string;

  @Field()
  name!: string;

  @Field()
  email!: string;

  @Field({ nullable: true })
  avatarUrl?: string | null;
}

@ObjectType()
class CrmProjectType {
  @Field(() => ID)
  id!: string;

  @Field()
  name!: string;

  @Field()
  key!: string;

  @Field({ nullable: true })
  description?: string | null;

  @Field(() => ID)
  workspaceId!: string;

  @Field(() => ID, { nullable: true })
  leadId?: string | null;

  @Field(() => UserInfo, { nullable: true })
  lead?: UserInfo | null;

  @Field(() => Date)
  createdAt!: Date;

  @Field(() => Date)
  updatedAt!: Date;

  @Field(() => Int, { nullable: true })
  issuesCount?: number;
}

@ObjectType()
class CrmIssueType {
  @Field(() => ID)
  id!: string;

  @Field()
  title!: string;

  @Field({ nullable: true })
  description?: string | null;

  @Field(() => IssueStatusEnum)
  status!: IssueStatus;

  @Field(() => IssuePriorityEnum)
  priority!: IssuePriority;

  @Field(() => IssueTypeEnum)
  type!: IssueType;

  @Field(() => ID)
  projectId!: string;

  @Field(() => ID, { nullable: true })
  assigneeId?: string | null;

  @Field(() => ID)
  reporterId!: string;

  @Field(() => ID, { nullable: true })
  sprintId?: string | null;

  @Field(() => ID, { nullable: true })
  parentId?: string | null;

  @Field(() => Int, { nullable: true })
  storyPoints?: number | null;

  @Field(() => Date, { nullable: true })
  dueDate?: Date | null;

  @Field(() => Date)
  createdAt!: Date;

  @Field(() => Date)
  updatedAt!: Date;

  @Field(() => CrmProjectType, { nullable: true })
  project?: CrmProjectWithRelations;

  @Field(() => UserInfo, { nullable: true })
  assignee?: UserInfo | null;

  @Field(() => UserInfo, { nullable: true })
  reporter?: UserInfo | null;

  @Field(() => Int, { nullable: true })
  commentsCount?: number;

  @Field(() => Int, { nullable: true })
  timeLogsCount?: number;
}

@ObjectType()
class CrmSprintType {
  @Field(() => ID)
  id!: string;

  @Field()
  name!: string;

  @Field({ nullable: true })
  goal?: string | null;

  @Field(() => ID)
  projectId!: string;

  @Field(() => Date)
  startDate!: Date;

  @Field(() => Date)
  endDate!: Date;

  @Field()
  isActive!: boolean;

  @Field(() => Date)
  createdAt!: Date;

  @Field(() => Date)
  updatedAt!: Date;

  @Field(() => Int, { nullable: true })
  issuesCount?: number;
}

@ObjectType()
class CrmCommentType {
  @Field(() => ID)
  id!: string;

  @Field()
  content!: string;

  @Field(() => ID)
  issueId!: string;

  @Field(() => ID)
  authorId!: string;

  @Field(() => UserInfo, { nullable: true })
  author?: UserInfo | null;

  @Field(() => Date)
  createdAt!: Date;

  @Field(() => Date)
  updatedAt!: Date;
}

@ObjectType()
class CrmTimeLogType {
  @Field(() => ID)
  id!: string;

  @Field(() => ID)
  issueId!: string;

  @Field(() => ID)
  userId!: string;

  @Field(() => Int)
  timeSpent!: number;

  @Field({ nullable: true })
  description?: string | null;

  @Field(() => Date)
  loggedAt!: Date;

  @Field(() => Date)
  createdAt!: Date;

  @Field(() => UserInfo, { nullable: true })
  user?: UserInfo | null;
}

// ========== Input Types ==========

@InputType()
class CreateProjectInput {
  @Field()
  name!: string;

  @Field()
  key!: string;

  @Field({ nullable: true })
  description?: string;

  @Field(() => ID)
  workspaceId!: string;

  @Field(() => ID, { nullable: true })
  leadId?: string;
}

@InputType()
class UpdateProjectInput {
  @Field({ nullable: true })
  name?: string;

  @Field({ nullable: true })
  key?: string;

  @Field({ nullable: true })
  description?: string;

  @Field(() => ID, { nullable: true })
  leadId?: string;
}

@InputType()
class CreateIssueInput {
  @Field()
  title!: string;

  @Field({ nullable: true })
  description?: string;

  @Field(() => ID)
  projectId!: string;

  @Field(() => ID, { nullable: true })
  assigneeId?: string;

  @Field(() => ID)
  reporterId!: string;

  @Field(() => ID, { nullable: true })
  sprintId?: string;

  @Field(() => ID, { nullable: true })
  parentId?: string;

  @Field(() => IssueStatusEnum, { nullable: true })
  status?: IssueStatus;

  @Field(() => IssuePriorityEnum, { nullable: true })
  priority?: IssuePriority;

  @Field(() => IssueTypeEnum, { nullable: true })
  type?: IssueType;

  @Field(() => Int, { nullable: true })
  storyPoints?: number;

  @Field(() => Date, { nullable: true })
  dueDate?: Date;
}

@InputType()
class UpdateIssueInput {
  @Field({ nullable: true })
  title?: string;

  @Field({ nullable: true })
  description?: string;

  @Field(() => ID, { nullable: true })
  assigneeId?: string;

  @Field(() => ID, { nullable: true })
  sprintId?: string;

  @Field(() => IssueStatusEnum, { nullable: true })
  status?: IssueStatus;

  @Field(() => IssuePriorityEnum, { nullable: true })
  priority?: IssuePriority;

  @Field(() => IssueTypeEnum, { nullable: true })
  type?: IssueType;

  @Field(() => Int, { nullable: true })
  storyPoints?: number;

  @Field(() => Date, { nullable: true })
  dueDate?: Date;
}

@InputType()
class CreateSprintInput {
  @Field()
  name!: string;

  @Field({ nullable: true })
  goal?: string;

  @Field(() => ID)
  projectId!: string;

  @Field(() => Date)
  startDate!: Date;

  @Field(() => Date)
  endDate!: Date;
}

@InputType()
class UpdateSprintInput {
  @Field({ nullable: true })
  name?: string;

  @Field({ nullable: true })
  goal?: string;

  @Field(() => Date, { nullable: true })
  startDate?: Date;

  @Field(() => Date, { nullable: true })
  endDate?: Date;

  @Field({ nullable: true })
  isActive?: boolean;
}

@InputType()
class CreateCommentInput {
  @Field()
  content!: string;

  @Field(() => ID)
  issueId!: string;
}

@InputType()
class UpdateCommentInput {
  @Field()
  content!: string;
}

@InputType()
class CreateTimeLogInput {
  @Field(() => ID)
  issueId!: string;

  @Field(() => Int)
  timeSpent!: number;

  @Field({ nullable: true })
  description?: string;

  @Field(() => Date)
  loggedAt!: Date;
}

// ========== Resolvers ==========

@Auth()
@Resolver(() => CrmProjectType)
export class CrmProjectResolver {
  constructor(
    private readonly crmService: CrmService,
    private readonly permission: PermissionService
  ) {}

  @Query(() => CrmProjectType)
  async crmProject(
    @CurrentUser() user: { id: string },
    @Args('id', { type: () => ID }) id: string
  ): Promise<CrmProjectWithRelations> {
    const project = await this.crmService.getProject(id);

    // Check workspace access
    const hasAccess = await this.permission.isWorkspaceMember(
      project.workspaceId,
      user.id
    );

    if (!hasAccess) {
      throw new ForbiddenException('No access to this project');
    }

    return project;
  }

  @Query(() => [CrmProjectType])
  async crmProjectsByWorkspace(
    @CurrentUser() user: { id: string },
    @Args('workspaceId', { type: () => ID }) workspaceId: string
  ): Promise<CrmProjectWithRelations[]> {
    const hasAccess = await this.permission.isWorkspaceMember(
      workspaceId,
      user.id
    );

    if (!hasAccess) {
      throw new ForbiddenException('No access to this workspace');
    }

    return this.crmService.getProjectsByWorkspace(workspaceId);
  }

  @Mutation(() => CrmProjectType)
  async createCrmProject(
    @CurrentUser() user: { id: string },
    @Args('input') input: CreateProjectInput
  ): Promise<CrmProjectWithRelations> {
    const hasAccess = await this.permission.isWorkspaceMember(
      input.workspaceId,
      user.id
    );

    if (!hasAccess) {
      throw new ForbiddenException('No access to this workspace');
    }

    return this.crmService.createProject(input);
  }

  @Mutation(() => CrmProjectType)
  async updateCrmProject(
    @CurrentUser() user: { id: string },
    @Args('id', { type: () => ID }) id: string,
    @Args('input') input: UpdateProjectInput
  ): Promise<CrmProjectWithRelations> {
    const project = await this.crmService.getProject(id);

    const hasAccess = await this.permission.isWorkspaceMember(
      project.workspaceId,
      user.id
    );

    if (!hasAccess) {
      throw new ForbiddenException('No access to this project');
    }

    return this.crmService.updateProject(id, input);
  }

  @Mutation(() => CrmProjectType)
  async deleteCrmProject(
    @CurrentUser() user: { id: string },
    @Args('id', { type: () => ID }) id: string
  ): Promise<CrmProjectWithRelations> {
    const project = await this.crmService.getProject(id);

    const hasAccess = await this.permission.isWorkspaceMember(
      project.workspaceId,
      user.id
    );

    if (!hasAccess) {
      throw new ForbiddenException('No access to this project');
    }

    return this.crmService.deleteProject(id);
  }
}

@Auth()
@Resolver(() => CrmIssueType)
export class CrmIssueResolver {
  constructor(
    private readonly crmService: CrmService,
    private readonly permission: PermissionService,
    @Inject(PrismaClient) private readonly prisma: PrismaClientType
  ) {}

  @Query(() => CrmIssueType)
  async crmIssue(
    @CurrentUser() user: { id: string },
    @Args('id', { type: () => ID }) id: string
  ): Promise<CrmIssueWithRelations> {
    const issue = await this.crmService.getIssue(id);
    const project = await this.crmService.getProject(issue.projectId);

    const hasAccess = await this.permission.isWorkspaceMember(
      project.workspaceId,
      user.id
    );

    if (!hasAccess) {
      throw new ForbiddenException('No access to this issue');
    }

    return issue;
  }

  @Query(() => [CrmIssueType])
  async crmIssuesByProject(
    @CurrentUser() user: { id: string },
    @Args('projectId', { type: () => ID }) projectId: string,
    @Args('status', { type: () => IssueStatusEnum, nullable: true }) status?: IssueStatus,
    @Args('assigneeId', { type: () => ID, nullable: true }) assigneeId?: string,
    @Args('sprintId', { type: () => ID, nullable: true }) sprintId?: string
  ): Promise<CrmIssueWithRelations[]> {
    const project = await this.crmService.getProject(projectId);

    const hasAccess = await this.permission.isWorkspaceMember(
      project.workspaceId,
      user.id
    );

    if (!hasAccess) {
      throw new ForbiddenException('No access to this project');
    }

    return this.crmService.getIssuesByProject(projectId, {
      status: status as string,
      assigneeId,
      sprintId,
    });
  }

  @Mutation(() => CrmIssueType)
  async createCrmIssue(
    @CurrentUser() user: { id: string },
    @Args('input') input: CreateIssueInput
  ): Promise<CrmIssueWithRelations> {
    const project = await this.crmService.getProject(input.projectId);

    const hasAccess = await this.permission.isWorkspaceMember(
      project.workspaceId,
      user.id
    );

    if (!hasAccess) {
      throw new ForbiddenException('No access to this project');
    }

    return this.crmService.createIssue(input);
  }

  @Mutation(() => CrmIssueType)
  async updateCrmIssue(
    @CurrentUser() user: { id: string },
    @Args('id', { type: () => ID }) id: string,
    @Args('input') input: UpdateIssueInput
  ): Promise<CrmIssueWithRelations> {
    const issue = await this.crmService.getIssue(id);
    const project = await this.crmService.getProject(issue.projectId);

    const hasAccess = await this.permission.isWorkspaceMember(
      project.workspaceId,
      user.id
    );

    if (!hasAccess) {
      throw new ForbiddenException('No access to this issue');
    }

    return this.crmService.updateIssue(id, input);
  }

  @Mutation(() => CrmIssueType)
  async deleteCrmIssue(
    @CurrentUser() user: { id: string },
    @Args('id', { type: () => ID }) id: string
  ): Promise<CrmIssueWithRelations> {
    const issue = await this.crmService.getIssue(id);
    const project = await this.crmService.getProject(issue.projectId);

    const hasAccess = await this.permission.isWorkspaceMember(
      project.workspaceId,
      user.id
    );

    if (!hasAccess) {
      throw new ForbiddenException('No access to this issue');
    }

    return this.crmService.deleteIssue(id);
  }

  @ResolveField(() => [CrmCommentType])
  async comments(
    @Parent() issue: CrmIssueType
  ): Promise<CrmCommentWithRelations[]> {
    return this.crmService.getCommentsByIssue(this.prisma, issue.id);
  }

  @ResolveField(() => [CrmTimeLogType])
  async timeLogs(
    @Parent() issue: CrmIssueType
  ): Promise<CrmTimeLogWithRelations[]> {
    return this.crmService.getTimeLogsByIssue(this.prisma, issue.id);
  }
}

@Auth()
@Resolver(() => CrmSprintType)
export class CrmSprintResolver {
  constructor(
    private readonly crmService: CrmService,
    private readonly permission: PermissionService,
    @Inject(PrismaClient) private readonly prisma: PrismaClientType
  ) {}

  @Query(() => CrmSprintType)
  async crmSprint(
    @CurrentUser() user: { id: string },
    @Args('id', { type: () => ID }) id: string
  ): Promise<CrmSprintWithRelations> {
    const sprint = await this.crmService.getSprint(this.prisma, id);
    const project = await this.crmService.getProject(sprint.projectId);

    const hasAccess = await this.permission.isWorkspaceMember(
      project.workspaceId,
      user.id
    );

    if (!hasAccess) {
      throw new ForbiddenException('No access to this sprint');
    }

    return sprint;
  }

  @Query(() => [CrmSprintType])
  async crmSprintsByProject(
    @CurrentUser() user: { id: string },
    @Args('projectId', { type: () => ID }) projectId: string
  ): Promise<CrmSprintWithRelations[]> {
    const project = await this.crmService.getProject(projectId);

    const hasAccess = await this.permission.isWorkspaceMember(
      project.workspaceId,
      user.id
    );

    if (!hasAccess) {
      throw new ForbiddenException('No access to this project');
    }

    return this.crmService.getSprintsByProject(this.prisma, projectId);
  }

  @Mutation(() => CrmSprintType)
  async createCrmSprint(
    @CurrentUser() user: { id: string },
    @Args('input') input: CreateSprintInput
  ): Promise<CrmSprintWithRelations> {
    const project = await this.crmService.getProject(input.projectId);

    const hasAccess = await this.permission.isWorkspaceMember(
      project.workspaceId,
      user.id
    );

    if (!hasAccess) {
      throw new ForbiddenException('No access to this project');
    }

    return this.crmService.createSprint(this.prisma, input);
  }

  @Mutation(() => CrmSprintType)
  async updateCrmSprint(
    @CurrentUser() user: { id: string },
    @Args('id', { type: () => ID }) id: string,
    @Args('input') input: UpdateSprintInput
  ): Promise<CrmSprintWithRelations> {
    const sprint = await this.crmService.getSprint(this.prisma, id);
    const project = await this.crmService.getProject(sprint.projectId);

    const hasAccess = await this.permission.isWorkspaceMember(
      project.workspaceId,
      user.id
    );

    if (!hasAccess) {
      throw new ForbiddenException('No access to this sprint');
    }

    return this.crmService.updateSprint(this.prisma, id, input);
  }

  @Mutation(() => CrmSprintType)
  async deleteCrmSprint(
    @CurrentUser() user: { id: string },
    @Args('id', { type: () => ID }) id: string
  ): Promise<CrmSprintWithRelations> {
    const sprint = await this.crmService.getSprint(this.prisma, id);
    const project = await this.crmService.getProject(sprint.projectId);

    const hasAccess = await this.permission.isWorkspaceMember(
      project.workspaceId,
      user.id
    );

    if (!hasAccess) {
      throw new ForbiddenException('No access to this sprint');
    }

    return this.crmService.deleteSprint(this.prisma, id);
  }
}

@Auth()
@Resolver(() => CrmCommentType)
export class CrmCommentResolver {
  constructor(
    private readonly crmService: CrmService,
    private readonly permission: PermissionService,
    @Inject(PrismaClient) private readonly prisma: PrismaClientType
  ) {}

  @Mutation(() => CrmCommentType)
  async createCrmComment(
    @CurrentUser() user: { id: string },
    @Args('input') input: CreateCommentInput
  ): Promise<CrmCommentWithRelations> {
    const issue = await this.crmService.getIssue(input.issueId);
    const project = await this.crmService.getProject(issue.projectId);

    const hasAccess = await this.permission.isWorkspaceMember(
      project.workspaceId,
      user.id
    );

    if (!hasAccess) {
      throw new ForbiddenException('No access to this issue');
    }

    return this.crmService.createComment(this.prisma, {
      ...input,
      authorId: user.id,
    });
  }

  @Mutation(() => CrmCommentType)
  async updateCrmComment(
    @CurrentUser() user: { id: string },
    @Args('id', { type: () => ID }) id: string,
    @Args('input') input: UpdateCommentInput
  ): Promise<CrmCommentWithRelations> {
    const comment = await this.prisma.crmComment.findUnique({
      where: { id },
      include: { issue: { include: { project: true } } },
    });

    if (!comment) {
      throw new ForbiddenException('Comment not found');
    }

    if (comment.authorId !== user.id) {
      throw new ForbiddenException('Can only edit your own comments');
    }

    return this.crmService.updateComment(this.prisma, id, input);
  }

  @Mutation(() => CrmCommentType)
  async deleteCrmComment(
    @CurrentUser() user: { id: string },
    @Args('id', { type: () => ID }) id: string
  ): Promise<CrmCommentWithRelations> {
    const comment = await this.prisma.crmComment.findUnique({
      where: { id },
    });

    if (!comment) {
      throw new ForbiddenException('Comment not found');
    }

    if (comment.authorId !== user.id) {
      throw new ForbiddenException('Can only delete your own comments');
    }

    return this.crmService.deleteComment(this.prisma, id);
  }
}

@Auth()
@Resolver(() => CrmTimeLogType)
export class CrmTimeLogResolver {
  constructor(
    private readonly crmService: CrmService,
    private readonly permission: PermissionService,
    @Inject(PrismaClient) private readonly prisma: PrismaClientType
  ) {}

  @Mutation(() => CrmTimeLogType)
  async createCrmTimeLog(
    @CurrentUser() user: { id: string },
    @Args('input') input: CreateTimeLogInput
  ): Promise<CrmTimeLogWithRelations> {
    const issue = await this.crmService.getIssue(input.issueId);
    const project = await this.crmService.getProject(issue.projectId);

    const hasAccess = await this.permission.isWorkspaceMember(
      project.workspaceId,
      user.id
    );

    if (!hasAccess) {
      throw new ForbiddenException('No access to this issue');
    }

    return this.crmService.createTimeLog(this.prisma, {
      ...input,
      userId: user.id,
    });
  }

  @Mutation(() => CrmTimeLogType)
  async deleteCrmTimeLog(
    @CurrentUser() user: { id: string },
    @Args('id', { type: () => ID }) id: string
  ): Promise<CrmTimeLogWithRelations> {
    const timeLog = await this.prisma.crmTimeLog.findUnique({
      where: { id },
    });

    if (!timeLog) {
      throw new ForbiddenException('Time log not found');
    }

    if (timeLog.userId !== user.id) {
      throw new ForbiddenException('Can only delete your own time logs');
    }

    return this.crmService.deleteTimeLog(this.prisma, id);
  }

  @Query(() => Int)
  async crmIssueTotalTime(
    @CurrentUser() user: { id: string },
    @Args('issueId', { type: () => ID }) issueId: string
  ): Promise<number> {
    const issue = await this.crmService.getIssue(issueId);
    const project = await this.crmService.getProject(issue.projectId);

    const hasAccess = await this.permission.isWorkspaceMember(
      project.workspaceId,
      user.id
    );

    if (!hasAccess) {
      throw new ForbiddenException('No access to this issue');
    }

    return this.crmService.getTotalTimeSpent(this.prisma, issueId);
  }
}
