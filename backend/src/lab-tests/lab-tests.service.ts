import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { LabTest } from './entities/lab-test.entity';
import { CreateLabTestDto } from './dto/create-lab-test.dto';

@Injectable()
export class LabTestsService {
  constructor(@InjectRepository(LabTest) private repo: Repository<LabTest>) {}

  findByPatient(patientId: string) {
    return this.repo.find({ where: { patientId }, order: { createdAt: 'DESC' } });
  }

  create(dto: CreateLabTestDto) {
    return this.repo.save(this.repo.create(dto));
  }
}
