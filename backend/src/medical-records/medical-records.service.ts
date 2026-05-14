import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { IsString, IsOptional, IsNumber } from 'class-validator';
import { MedicalRecord } from './entities/medical-record.entity';

export class CreateMedicalRecordDto {
  @IsString()
  patientId: string;

  @IsString()
  @IsOptional()
  doctorId?: string;

  @IsString()
  @IsOptional()
  appointmentId?: string;

  @IsString()
  @IsOptional()
  diagnosis?: string;

  @IsOptional()
  notes?: Record<string, any>;

  @IsString()
  @IsOptional()
  bloodPressure?: string;

  @IsNumber()
  @IsOptional()
  heartRate?: number;

  @IsNumber()
  @IsOptional()
  temperature?: number;

  @IsNumber()
  @IsOptional()
  weight?: number;
}

@Injectable()
export class MedicalRecordsService {
  constructor(@InjectRepository(MedicalRecord) private repo: Repository<MedicalRecord>) {}

  create(dto: CreateMedicalRecordDto) {
    const record = this.repo.create(dto);
    return this.repo.save(record);
  }

  findByPatient(patientId: string) {
    return this.repo.find({ where: { patientId }, order: { createdAt: 'DESC' } });
  }

  async findOne(id: string) {
    const r = await this.repo.findOne({ where: { id } });
    if (!r) throw new NotFoundException(`Запис #${id} не знайдено`);
    return r;
  }

  async update(id: string, dto: Partial<CreateMedicalRecordDto>) {
    await this.findOne(id);
    await this.repo.update(id, dto);
    return this.findOne(id);
  }
}
