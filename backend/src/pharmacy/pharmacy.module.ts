import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Medication } from './entities/medication.entity';
import { Prescription } from './entities/prescription.entity';
import { PharmacyController, PrescriptionsController } from './pharmacy.controller';
import { PharmacyService } from './pharmacy.service';

@Module({
  imports: [TypeOrmModule.forFeature([Medication, Prescription])],
  controllers: [PharmacyController, PrescriptionsController],
  providers: [PharmacyService],
  exports: [PharmacyService],
})
export class PharmacyModule {}
