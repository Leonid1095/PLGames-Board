import { Module } from '@nestjs/common';

import { PrismaModule } from '../../base/prisma';
import { PermissionModule } from '../../core/permission';
import { QuotaModule } from '../../core/quota';
import { WorkspaceModule } from '../../core/workspaces';
import { LicenseResolver } from './resolver';
import { LicenseService } from './service';

@Module({
  imports: [PrismaModule, QuotaModule, PermissionModule, WorkspaceModule],
  providers: [LicenseService, LicenseResolver],
})
export class LicenseModule {}
