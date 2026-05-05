import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between, MoreThanOrEqual, LessThanOrEqual } from 'typeorm';
import { Appointment, AppointmentStatus } from './entities/appointment.entity';
import { CreateAppointmentDto } from './dto/create-appointment.dto';

@Injectable()
export class AppointmentsService {
  constructor(@InjectRepository(Appointment) private repo: Repository<Appointment>) {}

  async create(dto: CreateAppointmentDto) {
    const appointment = this.repo.create({
      ...dto,
      startTime: new Date(dto.startTime),
      endTime: new Date(dto.endTime),
    });
    return this.repo.save(appointment);
  }

  findAll() {
    return this.repo.find({ order: { startTime: 'ASC' } });
  }

  async findToday() {
    const start = new Date();
    start.setHours(0, 0, 0, 0);
    const end = new Date();
    end.setHours(23, 59, 59, 999);
    return this.repo.find({
      where: { startTime: Between(start, end), status: AppointmentStatus.SCHEDULED },
      order: { startTime: 'ASC' },
    });
  }

  async findSlots(doctorId: string, date: string): Promise<any[]> {
    const day = new Date(date);
    const dayStart = new Date(day); dayStart.setHours(0, 0, 0, 0);
    const dayEnd = new Date(day); dayEnd.setHours(23, 59, 59, 999);

    const booked = await this.repo.find({
      where: {
        doctorId,
        startTime: Between(dayStart, dayEnd),
        status: AppointmentStatus.SCHEDULED,
      },
      select: ['startTime'],
    });

    const bookedTimes = booked.map((a) => {
      const d = new Date(a.startTime);
      return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
    });

    const slots = ['08:00','08:30','09:00','09:30','10:00','10:30','11:00','11:30',
                   '14:00','14:30','15:00','15:30','16:00','16:30'];
    return slots.map((t) => ({ time: t, busy: bookedTimes.includes(t) }));
  }

  async findOne(id: string) {
    const a = await this.repo.findOne({ where: { id } });
    if (!a) throw new NotFoundException(`Прийом #${id} не знайдено`);
    return a;
  }

  async cancel(id: string) {
    await this.findOne(id);
    await this.repo.update(id, { status: AppointmentStatus.CANCELLED });
    return this.findOne(id);
  }

  async complete(id: string) {
    await this.findOne(id);
    await this.repo.update(id, { status: AppointmentStatus.COMPLETED });
    return this.findOne(id);
  }

  countToday() {
    const start = new Date(); start.setHours(0, 0, 0, 0);
    const end = new Date(); end.setHours(23, 59, 59, 999);
    return this.repo.count({ where: { startTime: Between(start, end) } });
  }
}
