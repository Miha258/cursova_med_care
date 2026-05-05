import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Doctor } from './entities/doctor.entity';

@Injectable()
export class DoctorsService {
  constructor(@InjectRepository(Doctor) private repo: Repository<Doctor>) {}

  findAll(specialization?: string) {
    if (specialization) {
      return this.repo.find({ where: { specialization, isActive: true }, order: { lastName: 'ASC' } });
    }
    return this.repo.find({ where: { isActive: true }, order: { specialization: 'ASC', lastName: 'ASC' } });
  }

  findOne(id: string) {
    return this.repo.findOne({ where: { id } });
  }

  async create(dto: Partial<Doctor>) {
    const doc = this.repo.create(dto);
    return this.repo.save(doc);
  }
}
