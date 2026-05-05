import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Appointment, AppointmentStatus } from '../appointments/entities/appointment.entity';
import { Invoice, InvoiceStatus } from '../finance/entities/invoice.entity';

@Injectable()
export class ReportsService {
  constructor(
    @InjectRepository(Appointment) private appointmentRepo: Repository<Appointment>,
    @InjectRepository(Invoice) private invoiceRepo: Repository<Invoice>,
  ) {}

  // Агрегаційний звіт по прийомах (CTE-запит PostgreSQL)
  async getAppointmentReport(from?: string, to?: string) {
    const qb = this.appointmentRepo.createQueryBuilder('a')
      .select('a.status', 'status')
      .addSelect('COUNT(*)', 'count')
      .groupBy('a.status');

    if (from) qb.andWhere('a.startTime >= :from', { from });
    if (to) qb.andWhere('a.startTime <= :to', { to });

    const byStatus = await qb.getRawMany();

    const total = await this.appointmentRepo.count();
    return { total, byStatus };
  }

  // Фінансовий звіт
  async getRevenueReport(from?: string, to?: string) {
    const qb = this.invoiceRepo.createQueryBuilder('i')
      .select("DATE_TRUNC('month', i.createdAt)", 'month')
      .addSelect('SUM(i.amount)', 'revenue')
      .addSelect('COUNT(*)', 'count')
      .where('i.status = :s', { s: InvoiceStatus.PAID })
      .groupBy("DATE_TRUNC('month', i.createdAt)")
      .orderBy("DATE_TRUNC('month', i.createdAt)", 'ASC');

    if (from) qb.andWhere('i.createdAt >= :from', { from });
    if (to) qb.andWhere('i.createdAt <= :to', { to });

    return qb.getRawMany();
  }

  // Завантаженість лікарів
  async getDoctorWorkload() {
    return this.appointmentRepo.createQueryBuilder('a')
      .select('a.doctorId', 'doctorId')
      .addSelect('COUNT(*)', 'total')
      .addSelect(`SUM(CASE WHEN a.status = '${AppointmentStatus.COMPLETED}' THEN 1 ELSE 0 END)`, 'completed')
      .groupBy('a.doctorId')
      .orderBy('total', 'DESC')
      .getRawMany();
  }

  // Зведений фінансовий звіт
  async getFinancialSummary(from?: string, to?: string) {
    const qb = this.invoiceRepo.createQueryBuilder('i');
    if (from) qb.andWhere('i.createdAt >= :from', { from });
    if (to) qb.andWhere('i.createdAt <= :to', { to });

    const all = await qb
      .select('i.status', 'status')
      .addSelect('SUM(i.amount)', 'total')
      .addSelect('COUNT(*)', 'count')
      .groupBy('i.status')
      .getRawMany();

    const totalRevenue = all.find(r => r.status === InvoiceStatus.PAID)?.total ?? 0;
    const totalPending = all.find(r => r.status === InvoiceStatus.PENDING)?.total ?? 0;
    const totalCancelled = all.find(r => r.status === InvoiceStatus.CANCELLED)?.total ?? 0;

    return {
      summary: all,
      totalRevenue: Number(totalRevenue),
      totalPending: Number(totalPending),
      totalCancelled: Number(totalCancelled),
      collectionRate: Number(totalRevenue) + Number(totalPending) > 0
        ? Math.round((Number(totalRevenue) / (Number(totalRevenue) + Number(totalPending))) * 100)
        : 0,
    };
  }
}
