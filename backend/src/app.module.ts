import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { PatientsModule } from './patients/patients.module';
import { DoctorsModule } from './doctors/doctors.module';
import { AppointmentsModule } from './appointments/appointments.module';
import { MedicalRecordsModule } from './medical-records/medical-records.module';
import { PharmacyModule } from './pharmacy/pharmacy.module';
import { FinanceModule } from './finance/finance.module';
import { DashboardModule } from './dashboard/dashboard.module';
import { ReportsModule } from './reports/reports.module';
import { LabTestsModule } from './lab-tests/lab-tests.module';
import { SeedModule } from './seed/seed.module';
import { MailerModule } from './mailer/mailer.module';
import { PaymentModule } from './payment/payment.module';

// Entities
import { User } from './users/entities/user.entity';
import { Patient } from './patients/entities/patient.entity';
import { Doctor } from './doctors/entities/doctor.entity';
import { Appointment } from './appointments/entities/appointment.entity';
import { MedicalRecord } from './medical-records/entities/medical-record.entity';
import { Medication } from './pharmacy/entities/medication.entity';
import { Prescription } from './pharmacy/entities/prescription.entity';
import { Invoice } from './finance/entities/invoice.entity';
import { Ward } from './wards/entities/ward.entity';
import { AuditLog } from './common/entities/audit-log.entity';
import { LabTest } from './lab-tests/entities/lab-test.entity';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT) || 5432,
      username: process.env.DB_USERNAME || 'postgres',
      password: process.env.DB_PASSWORD || 'postgres',
      database: process.env.DB_NAME || 'medcare',
      entities: [User, Patient, Doctor, Appointment, MedicalRecord, Medication, Prescription, Invoice, Ward, AuditLog, LabTest],
      synchronize: true, // AUTO-MIGRATE: TypeORM creates all 10 tables on startup
      logging: false,
    }),
    AuthModule,
    UsersModule,
    PatientsModule,
    DoctorsModule,
    AppointmentsModule,
    MedicalRecordsModule,
    PharmacyModule,
    FinanceModule,
    DashboardModule,
    ReportsModule,
    LabTestsModule,
    SeedModule,
    MailerModule,
    PaymentModule,
  ],
})
export class AppModule {}
