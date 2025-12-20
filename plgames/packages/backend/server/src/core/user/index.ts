import { Module } from '@nestjs/common';

import { PrismaModule } from '../prisma';
import { PermissionModule } from '../permission';
import { StorageModule } from '../storage';
import { UserAvatarController } from './controller';
import {
  UserManagementResolver,
  UserResolver,
  UserSettingsResolver,
} from './resolver';

@Module({
  imports: [PrismaModule, StorageModule, PermissionModule],
  providers: [UserResolver, UserManagementResolver, UserSettingsResolver],
  controllers: [UserAvatarController],
})
export class UserModule {}

export { PublicUserType, UserType, WorkspaceUserType } from './types';
