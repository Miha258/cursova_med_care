import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { LabTest } from './entities/lab-test.entity';
import { LabTestsController } from './lab-tests.controller';
import { LabTestsService } from './lab-tests.service';

@Module({
  imports: [TypeOrmModule.forFeature([LabTest])],
  controllers: [LabTestsController],
  providers: [LabTestsService],
})
export class LabTestsModule {}
