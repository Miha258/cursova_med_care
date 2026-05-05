import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Invoice, InvoiceStatus } from './entities/invoice.entity';

@Injectable()
export class FinanceService {
  constructor(@InjectRepository(Invoice) private repo: Repository<Invoice>) {}

  findAll() {
    return this.repo.find({ order: { createdAt: 'DESC' } });
  }

  findByPatient(patientId: string) {
    return this.repo.find({ where: { patientId }, order: { createdAt: 'DESC' } });
  }

  async create(dto: Partial<Invoice>) {
    const invoice = this.repo.create(dto);
    return this.repo.save(invoice);
  }

  async pay(id: string) {
    const invoice = await this.repo.findOne({ where: { id } });
    if (!invoice) throw new NotFoundException('Рахунок не знайдено');
    await this.repo.update(id, { status: InvoiceStatus.PAID, paidAt: new Date() });
    return this.repo.findOne({ where: { id } });
  }

  async getFinancialSummary() {
    const total = await this.repo
      .createQueryBuilder('i')
      .select('SUM(i.amount)', 'total')
      .where('i.status = :s', { s: InvoiceStatus.PAID })
      .getRawOne();
    const pending = await this.repo.count({ where: { status: InvoiceStatus.PENDING } });
    const paid = await this.repo.count({ where: { status: InvoiceStatus.PAID } });
    return { totalRevenue: total?.total || 0, pendingCount: pending, paidCount: paid };
  }
}
