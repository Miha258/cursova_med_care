import { Controller, Get, Post, Patch, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { FinanceService } from './finance.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { Invoice } from './entities/invoice.entity';

@ApiTags('finance')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('invoices')
export class FinanceController {
  constructor(private service: FinanceService) {}

  @Get()
  @ApiOperation({ summary: 'GET /invoices — всі рахунки' })
  findAll(@Query('patientId') patientId?: string) {
    if (patientId) return this.service.findByPatient(patientId);
    return this.service.findAll();
  }

  @Get('summary')
  @ApiOperation({ summary: 'GET /invoices/summary — фінансовий звіт (SQL-агрегація PostgreSQL)' })
  summary() {
    return this.service.getFinancialSummary();
  }

  @Post()
  @ApiOperation({ summary: 'POST /invoices — виставити рахунок' })
  create(@Body() dto: Partial<Invoice>) {
    return this.service.create(dto);
  }

  @Patch(':id/pay')
  @ApiOperation({ summary: 'PATCH /invoices/:id/pay — оплатити рахунок' })
  pay(@Param('id') id: string) {
    return this.service.pay(id);
  }
}
