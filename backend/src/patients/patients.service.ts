import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, ILike } from 'typeorm';
import { Patient } from './entities/patient.entity';
import { CreatePatientDto } from './dto/create-patient.dto';

@Injectable()
export class PatientsService {
  constructor(@InjectRepository(Patient) private repo: Repository<Patient>) {}

  create(dto: CreatePatientDto) {
    const patient = this.repo.create(dto);
    return this.repo.save(patient);
  }

  findAll(search?: string) {
    if (search) {
      return this.repo.find({
        where: [
          { firstName: ILike(`%${search}%`) },
          { lastName: ILike(`%${search}%`) },
          { insuranceNo: ILike(`%${search}%`) },
        ],
        order: { createdAt: 'DESC' },
      });
    }
    return this.repo.find({ order: { createdAt: 'DESC' } });
  }

  async findOne(id: string) {
    const patient = await this.repo.findOne({ where: { id } });
    if (!patient) throw new NotFoundException(`Пацієнта #${id} не знайдено`);
    return patient;
  }

  async update(id: string, dto: Partial<CreatePatientDto>) {
    await this.findOne(id);
    await this.repo.update(id, dto);
    return this.findOne(id);
  }

  async remove(id: string) {
    await this.findOne(id);
    await this.repo.delete(id);
    return { message: 'Пацієнта видалено' };
  }

  count() {
    return this.repo.count();
  }
}
