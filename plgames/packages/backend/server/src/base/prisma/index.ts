import './config';

import { Global, Module, Provider } from '@nestjs/common';
import type { PrismaClient as PrismaClientType } from '@prisma/client';
import pkg from '@prisma/client';
const { PrismaClient } = pkg;

import { PrismaFactory } from './factory';

// only `PrismaClient` can be injected
const clientProvider: Provider = {
  provide: PrismaClient,
  useFactory: (factory: PrismaFactory) => {
    return factory.get();
  },
  inject: [PrismaFactory],
};

@Global()
@Module({
  providers: [PrismaFactory, clientProvider],
  exports: [PrismaFactory, clientProvider],
})
export class PrismaModule { }
export { PrismaFactory };

export type PrismaTransaction = Parameters<
  Parameters<PrismaClientType['$transaction']>[0]
>[0];
