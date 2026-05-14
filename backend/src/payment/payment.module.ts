import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PaymentController } from './payment.controller';
import { FinanceModule } from '../finance/finance.module';
import { Appointment } from '../appointments/entities/appointment.entity';

@Module({
  imports: [FinanceModule, TypeOrmModule.forFeature([Appointment])],
  controllers: [PaymentController],
})
export class PaymentModule {}
