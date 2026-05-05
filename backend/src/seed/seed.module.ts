import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SeedService } from './seed.service';
import { User } from '../users/entities/user.entity';
import { Doctor } from '../doctors/entities/doctor.entity';
import { Medication } from '../pharmacy/entities/medication.entity';

@Module({
  imports: [TypeOrmModule.forFeature([User, Doctor, Medication])],
  providers: [SeedService],
})
export class SeedModule {}
