import { Controller, Get, Post, Patch, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { FinanceService } from './finance.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { Invoice, PaymentMethod } from './entities/invoice.entity';

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

  @Patch(':id/pay-method')
  @ApiOperation({ summary: 'PATCH /invoices/:id/pay-method — оплатити з вибором методу (card/apple_pay/google_pay)' })
  payWithMethod(@Param('id') id: string, @Body('paymentMethod') method: PaymentMethod) {
    return this.service.payWithMethod(id, method);
  }

  @Patch('by-appointment/:appointmentId/pay')
  @ApiOperation({ summary: 'PATCH /invoices/by-appointment/:appointmentId/pay — оплатити за ID прийому' })
  payByAppointment(@Param('appointmentId') appointmentId: string, @Body('paymentMethod') method: PaymentMethod) {
    return this.service.payByAppointmentId(appointmentId, method);
  }

  @Post('for-appointment')
  @ApiOperation({ summary: 'POST /invoices/for-appointment — виставити рахунок за прийом' })
  createForAppointment(@Body() dto: { patientId: string; appointmentId: string; amount: number; description?: string }) {
    return this.service.createForAppointment(dto);
  }
}
