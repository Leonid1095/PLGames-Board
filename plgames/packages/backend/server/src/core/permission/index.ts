import { Injectable, Module } from '@nestjs/common';

import { AccessControllerBuilder } from './builder';
import { DocAccessController } from './doc';
import { EventsListener } from './event';
import { Action } from './types';
import { WorkspaceAccessController } from './workspace';

@Injectable()
export class PermissionService {
  constructor(private readonly access: AccessControllerBuilder) {}

  async isWorkspaceMember(workspaceId: string, userId: string) {
    // Checks minimal workspace read permission for user
    return this.access.user(userId).workspace(workspaceId).can(Action.Workspace.Read);
  }
}

@Module({
  providers: [
    WorkspaceAccessController,
    DocAccessController,
    AccessControllerBuilder,
    EventsListener,
    PermissionService,
  ],
  exports: [AccessControllerBuilder, PermissionService],
})
export class PermissionModule {}

export { AccessControllerBuilder as AccessController } from './builder';
export {
  DOC_ACTIONS,
  type DocAction,
  DocRole,
  WORKSPACE_ACTIONS,
  type WorkspaceAction,
  WorkspaceRole,
} from './types';
