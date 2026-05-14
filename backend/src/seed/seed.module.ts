import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SeedService } from './seed.service';
import { User } from '../users/entities/user.entity';
import { Doctor } from '../doctors/entities/doctor.entity';
import { Patient } from '../patients/entities/patient.entity';
import { Appointment } from '../appointments/entities/appointment.entity';
import { MedicalRecord } from '../medical-records/entities/medical-record.entity';
import { Medication } from '../pharmacy/entities/medication.entity';
import { Prescription } from '../pharmacy/entities/prescription.entity';
import { Invoice } from '../finance/entities/invoice.entity';
import { Ward } from '../wards/entities/ward.entity';
import { LabTest } from '../lab-tests/entities/lab-test.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      User,
      Doctor,
      Patient,
      Appointment,
      MedicalRecord,
      Medication,
      Prescription,
      Invoice,
      Ward,
      LabTest,
    ]),
  ],
  providers: [SeedService],
})
export class SeedModule {}
