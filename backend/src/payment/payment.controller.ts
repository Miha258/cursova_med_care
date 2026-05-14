import { Controller, Get, Post, Param, Body, Res, NotFoundException } from '@nestjs/common';
import { Response } from 'express';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { FinanceService } from '../finance/finance.service';
import { PaymentMethod } from '../finance/entities/invoice.entity';
import { Appointment } from '../appointments/entities/appointment.entity';

@ApiTags('payment')
@Controller('pay')
export class PaymentController {
  constructor(
    private financeService: FinanceService,
    @InjectRepository(Appointment) private appointmentRepo: Repository<Appointment>,
  ) {}

  @Get('appointment/:appointmentId')
  @ApiOperation({ summary: 'GET /pay/appointment/:id — сторінка оплати (без авторизації)' })
  async getPaymentPage(@Param('appointmentId') appointmentId: string, @Res() res: Response) {
    const appointment = await this.appointmentRepo.findOne({ where: { id: appointmentId } });
    if (!appointment) throw new NotFoundException('Запис не знайдено');

    const invoice = await this.financeService.findByAppointmentId(appointmentId);
    const alreadyPaid = invoice?.status === 'paid';

    const d = new Date(appointment.startTime);
    const dateStr = `${d.getDate().toString().padStart(2, '0')}.${(d.getMonth() + 1).toString().padStart(2, '0')}.${d.getFullYear()}`;
    const timeStr = `${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`;
    const amount = invoice?.amount ?? 350;

    const patient = appointment.patient as any;
    const doctor = appointment.doctor as any;
    const patientName = patient ? `${patient.firstName} ${patient.lastName}` : 'Пацієнт';
    const doctorName = doctor ? `Д-р ${doctor.lastName} ${doctor.firstName}` : 'Лікар';
    const specialization = doctor?.specialization ?? '';

    const reasonLabels: Record<string, string> = {
      repeat: 'Повторний прийом',
      primary: 'Первинна консультація',
      preventive: 'Профілактичний огляд',
      emergency: 'Невідкладна допомога',
    };
    const reason = reasonLabels[appointment.reason] ?? appointment.reason;

    const html = `<!DOCTYPE html>
<html lang="uk">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Оплата прийому — MedCare</title>
<style>
  *{box-sizing:border-box;margin:0;padding:0}
  body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Arial,sans-serif;background:#f0f4f8;min-height:100vh;display:flex;align-items:center;justify-content:center;padding:16px}
  .wrap{width:100%;max-width:480px}
  .header{background:linear-gradient(135deg,#1565C0,#42A5F5);border-radius:20px 20px 0 0;padding:28px 28px 24px;color:#fff;text-align:center}
  .header h1{font-size:22px;font-weight:800;margin-bottom:4px}
  .header p{font-size:13px;opacity:.8}
  .card{background:#fff;border-radius:0 0 20px 20px;padding:24px;box-shadow:0 8px 32px rgba(0,0,0,.12)}
  .amount-box{background:#E3F2FD;border-radius:14px;padding:18px;text-align:center;margin-bottom:22px}
  .amount-label{font-size:12px;color:#1976D2;font-weight:700;letter-spacing:.5px;text-transform:uppercase}
  .amount-value{font-size:38px;font-weight:900;color:#0D47A1;margin-top:4px}
  .info-row{display:flex;justify-content:space-between;padding:11px 0;border-bottom:1px solid #F3F4F6;font-size:14px}
  .info-row:last-of-type{border-bottom:none}
  .info-label{color:#9CA3AF}
  .info-value{font-weight:700;color:#1a1a2e;text-align:right;max-width:65%}
  .methods-title{font-size:12px;font-weight:800;color:#374151;letter-spacing:.5px;text-transform:uppercase;margin:22px 0 10px}
  .method{display:flex;align-items:center;gap:14px;padding:14px 16px;border:2px solid #E5E7EB;border-radius:12px;cursor:pointer;margin-bottom:10px;transition:.15s}
  .method:hover{border-color:#90CAF9;background:#F0F8FF}
  .method.selected{border-color:#1976D2;background:#E3F2FD}
  .method-icon{font-size:22px;width:30px;text-align:center}
  .method-label{font-size:15px;font-weight:700;color:#1a1a2e}
  .method-check{margin-left:auto;font-size:20px;color:#1976D2;display:none}
  .method.selected .method-check{display:block}
  .pay-btn{width:100%;height:52px;background:#1976D2;color:#fff;border:none;border-radius:14px;font-size:16px;font-weight:800;cursor:pointer;margin-top:16px;transition:.15s;letter-spacing:.3px}
  .pay-btn:hover{background:#1565C0}
  .pay-btn:disabled{background:#B0BEC5;cursor:not-allowed}
  .success{text-align:center;padding:20px 0}
  .success-icon{font-size:56px;margin-bottom:12px}
  .success-title{font-size:22px;font-weight:900;color:#2E7D32;margin-bottom:6px}
  .success-sub{font-size:14px;color:#6B7280}
  .paid-badge{background:#E8F5E9;color:#2E7D32;border-radius:30px;padding:8px 20px;font-size:13px;font-weight:700;display:inline-block;margin-bottom:16px}
  .spinner{display:none;width:22px;height:22px;border:3px solid rgba(255,255,255,.4);border-top-color:#fff;border-radius:50%;animation:spin .7s linear infinite;margin:auto}
  @keyframes spin{to{transform:rotate(360deg)}}
</style>
</head>
<body>
<div class="wrap">
  <div class="header">
    <h1>🏥 MedCare CRM</h1>
    <p>Онлайн-оплата прийому</p>
  </div>
  <div class="card" id="mainCard">
    ${alreadyPaid ? `
    <div class="success">
      <div class="success-icon">✅</div>
      <div class="paid-badge">Оплачено</div>
      <div class="success-title">Рахунок вже оплачено</div>
      <div class="success-sub">Дякуємо за оплату!</div>
    </div>` : `
    <div class="amount-box">
      <div class="amount-label">До сплати</div>
      <div class="amount-value">${amount} ₴</div>
    </div>
    <div class="info-row"><span class="info-label">Пацієнт</span><span class="info-value">${patientName}</span></div>
    <div class="info-row"><span class="info-label">Лікар</span><span class="info-value">${doctorName}</span></div>
    <div class="info-row"><span class="info-label">Спеціалізація</span><span class="info-value">${specialization}</span></div>
    <div class="info-row"><span class="info-label">Дата</span><span class="info-value">${dateStr}</span></div>
    <div class="info-row"><span class="info-label">Час</span><span class="info-value">${timeStr}</span></div>
    <div class="info-row"><span class="info-label">Тип прийому</span><span class="info-value">${reason}</span></div>
    <div class="methods-title">Спосіб оплати</div>
    <div class="method" onclick="selectMethod(this,'card')">
      <span class="method-icon">💳</span>
      <span class="method-label">Банківська картка</span>
      <span class="method-check">✓</span>
    </div>
    <div class="method" onclick="selectMethod(this,'apple_pay')">
      <span class="method-icon">🍎</span>
      <span class="method-label">Apple Pay</span>
      <span class="method-check">✓</span>
    </div>
    <div class="method" onclick="selectMethod(this,'google_pay')">
      <span class="method-icon">🔵</span>
      <span class="method-label">Google Pay</span>
      <span class="method-check">✓</span>
    </div>
    <button class="pay-btn" id="payBtn" onclick="pay()" disabled>Обрати спосіб оплати</button>`}
  </div>
</div>
<script>
  var selected = null;
  function selectMethod(el, method) {
    document.querySelectorAll('.method').forEach(function(m){m.classList.remove('selected')});
    el.classList.add('selected');
    selected = method;
    var btn = document.getElementById('payBtn');
    btn.disabled = false;
    btn.textContent = 'Оплатити';
  }
  async function pay() {
    if (!selected) return;
    var btn = document.getElementById('payBtn');
    btn.disabled = true;
    btn.innerHTML = '<div class="spinner" style="display:block"></div>';
    try {
      var res = await fetch(window.location.href, {
        method: 'POST',
        headers: {'Content-Type':'application/json'},
        body: JSON.stringify({paymentMethod: selected})
      });
      if (res.ok) {
        document.getElementById('mainCard').innerHTML = '<div class="success"><div class="success-icon">🎉</div><div class="success-title">Оплату успішно здійснено!</div><div style="margin-top:8px;font-size:14px;color:#6B7280">Дякуємо, ваш запис підтверджено.<br>Ми чекаємо вас у призначений час.</div></div>';
      } else {
        alert('Помилка оплати. Спробуйте ще раз.');
        btn.disabled = false;
        btn.textContent = 'Оплатити';
      }
    } catch(e) {
      alert('Помилка мережі. Спробуйте ще раз.');
      btn.disabled = false;
      btn.textContent = 'Оплатити';
    }
  }
</script>
</body>
</html>`;

    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.send(html);
  }

  @Post('appointment/:appointmentId')
  @ApiOperation({ summary: 'POST /pay/appointment/:id — оплатити (без авторизації)' })
  async processPayment(
    @Param('appointmentId') appointmentId: string,
    @Body('paymentMethod') paymentMethod: PaymentMethod,
  ) {
    return this.financeService.payByAppointmentId(appointmentId, paymentMethod);
  }
}
