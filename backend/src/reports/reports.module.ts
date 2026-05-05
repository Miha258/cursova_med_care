import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Appointment } from '../appointments/entities/appointment.entity';
import { Invoice } from '../finance/entities/invoice.entity';
import { ReportsController } from './reports.controller';
import { ReportsService } from './reports.service';

@Module({
  imports: [TypeOrmModule.forFeature([Appointment, Invoice])],
  controllers: [ReportsController],
  providers: [ReportsService],
})
export class ReportsModule {}
