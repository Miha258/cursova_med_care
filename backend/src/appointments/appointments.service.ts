import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { Appointment, AppointmentStatus } from './entities/appointment.entity';
import { Patient } from '../patients/entities/patient.entity';
import { CreateAppointmentDto } from './dto/create-appointment.dto';
import { FinanceService } from '../finance/finance.service';
import { MailerService } from '../mailer/mailer.service';

export class UpdateAppointmentDto {
  startTime?: string;
  endTime?: string;
  doctorId?: string;
}

@Injectable()
export class AppointmentsService {
  constructor(
    @InjectRepository(Appointment) private repo: Repository<Appointment>,
    @InjectRepository(Patient) private patientRepo: Repository<Patient>,
    private financeService: FinanceService,
    private mailer: MailerService,
  ) {}

  async create(dto: CreateAppointmentDto) {
    const appointment = this.repo.create({
      ...dto,
      startTime: new Date(dto.startTime),
      endTime: new Date(dto.endTime),
    });
    const saved = await this.repo.save(appointment);

    await this.financeService.createForAppointment({
      patientId: saved.patientId,
      appointmentId: saved.id,
      amount: 350.00,
      description: `Прийом у лікаря`,
    });

    return saved;
  }

  findAll(patientId?: string) {
    return this.repo.find({
      where: patientId ? { patientId } : undefined,
      relations: ['patient', 'doctor'],
      order: { startTime: 'ASC' },
    });
  }

  async findToday() {
    const start = new Date();
    start.setHours(0, 0, 0, 0);
    const end = new Date();
    end.setHours(23, 59, 59, 999);
    return this.repo.find({
      where: { startTime: Between(start, end), status: AppointmentStatus.SCHEDULED },
      relations: ['patient', 'doctor'],
      order: { startTime: 'ASC' },
    });
  }

  async findSlots(doctorId: string, date: string): Promise<any[]> {
    const day = new Date(date);
    const dayStart = new Date(day); dayStart.setHours(0, 0, 0, 0);
    const dayEnd = new Date(day); dayEnd.setHours(23, 59, 59, 999);

    const booked = await this.repo.find({
      where: { doctorId, startTime: Between(dayStart, dayEnd), status: AppointmentStatus.SCHEDULED },
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
    const a = await this.repo.findOne({ where: { id }, relations: ['patient', 'doctor'] });
    if (!a) throw new NotFoundException(`Прийом #${id} не знайдено`);
    return a;
  }

  async update(id: string, dto: UpdateAppointmentDto) {
    const appointment = await this.findOne(id);
    const updateData: any = {};
    if (dto.startTime) updateData.startTime = new Date(dto.startTime);
    if (dto.endTime)   updateData.endTime   = new Date(dto.endTime);
    if (dto.doctorId)  updateData.doctorId  = dto.doctorId;
    await this.repo.update(id, updateData);

    // Send email notification to patient
    try {
      const patient = await this.patientRepo.findOne({ where: { id: appointment.patientId } });
      if (patient?.email) {
        const newStart = updateData.startTime ?? appointment.startTime;
        const d = new Date(newStart);
        const dateStr = `${d.getDate().toString().padStart(2,'0')}.${(d.getMonth()+1).toString().padStart(2,'0')}.${d.getFullYear()}`;
        const timeStr = `${d.getHours().toString().padStart(2,'0')}:${d.getMinutes().toString().padStart(2,'0')}`;
        await this.mailer.sendAppointmentUpdate({
          to: patient.email,
          patientName: `${patient.firstName} ${patient.lastName}`,
          date: dateStr,
          time: timeStr,
        });
      }
    } catch (_) {}

    return this.findOne(id);
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
