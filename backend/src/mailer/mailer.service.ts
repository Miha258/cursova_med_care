import { Injectable, Logger } from '@nestjs/common';
import * as nodemailer from 'nodemailer';

@Injectable()
export class MailerService {
  private readonly logger = new Logger(MailerService.name);
  private transporter: nodemailer.Transporter;

  constructor() {
    this.transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: process.env.MAIL_USER,
        pass: process.env.MAIL_PASSWORD,
      },
    });
  }

  async sendReceipt(dto: {
    to: string;
    patientName: string;
    doctorName: string;
    specialization: string;
    date: string;
    time: string;
    reason: string;
    appointmentId?: string;
  }) {
    const reasonLabels: Record<string, string> = {
      repeat: 'Повторний прийом',
      primary: 'Первинна консультація',
      preventive: 'Профілактичний огляд',
      emergency: 'Невідкладна допомога',
    };

    const html = `
<!DOCTYPE html>
<html lang="uk">
<head><meta charset="UTF-8"><style>
  body { font-family: Arial, sans-serif; background: #f5f7fa; margin: 0; padding: 20px; }
  .card { background: #fff; border-radius: 16px; max-width: 520px; margin: 0 auto; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
  .header { background: linear-gradient(135deg, #1976D2 0%, #42A5F5 100%); padding: 28px 32px; }
  .header h1 { color: #fff; margin: 0; font-size: 22px; font-weight: 800; }
  .header p { color: rgba(255,255,255,0.8); margin: 6px 0 0; font-size: 13px; }
  .body { padding: 28px 32px; }
  .badge { display: inline-block; background: #E8F5E9; color: #2E7D32; padding: 4px 14px; border-radius: 20px; font-size: 13px; font-weight: 700; margin-bottom: 20px; }
  .row { display: flex; justify-content: space-between; padding: 12px 0; border-bottom: 1px solid #f0f0f0; }
  .row:last-child { border-bottom: none; }
  .label { color: #9CA3AF; font-size: 13px; }
  .value { color: #1a1a2e; font-size: 14px; font-weight: 700; text-align: right; }
  .footer { background: #f8fafc; padding: 16px 32px; text-align: center; color: #9CA3AF; font-size: 12px; }
</style></head>
<body>
<div class="card">
  <div class="header">
    <h1>🏥 MedCare CRM</h1>
    <p>Підтвердження запису на прийом</p>
  </div>
  <div class="body">
    <div class="badge">✅ Запис підтверджено</div>
    <div class="row"><span class="label">Пацієнт</span><span class="value">${dto.patientName}</span></div>
    <div class="row"><span class="label">Лікар</span><span class="value">Д-р ${dto.doctorName}</span></div>
    <div class="row"><span class="label">Спеціалізація</span><span class="value">${dto.specialization}</span></div>
    <div class="row"><span class="label">Дата</span><span class="value">${dto.date}</span></div>
    <div class="row"><span class="label">Час</span><span class="value">${dto.time}</span></div>
    <div class="row"><span class="label">Тип прийому</span><span class="value">${reasonLabels[dto.reason] ?? dto.reason}</span></div>
    <div style="margin-top:24px;text-align:center;padding:20px 0;border-top:1px solid #f0f0f0">
      <a href="http://45.12.111.55:3001/api/pay/appointment/${dto.appointmentId ?? ''}" style="display:inline-block;background:#1976D2;color:#ffffff;text-decoration:none;padding:14px 36px;border-radius:30px;font-size:15px;font-weight:800;letter-spacing:.3px;font-family:Arial,sans-serif">&#128179; Оплатити онлайн</a>
      <p style="margin:10px 0 0;font-size:12px;color:#9CA3AF;font-family:Arial,sans-serif">Натисніть кнопку, щоб перейти до безпечної сторінки оплати</p>
    </div>
  </div>
  <div class="footer">
    MedCare CRM · Цей лист згенеровано автоматично · Не відповідайте на нього
  </div>
</div>
</body>
</html>`;

    try {
      await this.transporter.sendMail({
        from: `"MedCare CRM" <${process.env.MAIL_USER}>`,
        to: dto.to,
        subject: `✅ Запис підтверджено — ${dto.date} о ${dto.time}`,
        html,
      });
      this.logger.log(`Receipt sent to ${dto.to}`);
    } catch (err) {
      this.logger.error(`Failed to send receipt to ${dto.to}: ${err.message}`);
      throw err;
    }
  }

  async sendAppointmentUpdate(dto: { to: string; patientName: string; date: string; time: string }) {
    const html = `
<!DOCTYPE html><html lang="uk"><head><meta charset="UTF-8"><style>
  body { font-family: Arial, sans-serif; background: #f5f7fa; margin: 0; padding: 20px; }
  .card { background: #fff; border-radius: 16px; max-width: 520px; margin: 0 auto; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
  .header { background: linear-gradient(135deg, #F59E0B 0%, #FBBF24 100%); padding: 28px 32px; }
  .header h1 { color: #fff; margin: 0; font-size: 22px; font-weight: 800; }
  .header p { color: rgba(255,255,255,0.85); margin: 6px 0 0; font-size: 13px; }
  .body { padding: 28px 32px; }
  .row { display: flex; justify-content: space-between; padding: 12px 0; border-bottom: 1px solid #f0f0f0; }
  .row:last-child { border-bottom: none; }
  .label { color: #9CA3AF; font-size: 13px; }
  .value { color: #1a1a2e; font-size: 14px; font-weight: 700; }
  .footer { background: #f8fafc; padding: 16px 32px; text-align: center; color: #9CA3AF; font-size: 12px; }
</style></head><body>
<div class="card">
  <div class="header"><h1>🏥 MedCare CRM</h1><p>Зміна часу прийому</p></div>
  <div class="body">
    <p style="margin:0 0 16px;color:#374151;">Шановний(а) <b>${dto.patientName}</b>, ваш прийом було перенесено.</p>
    <div class="row"><span class="label">Нова дата</span><span class="value">${dto.date}</span></div>
    <div class="row"><span class="label">Новий час</span><span class="value">${dto.time}</span></div>
  </div>
  <div class="footer">MedCare CRM · Цей лист згенеровано автоматично</div>
</div></body></html>`;

    try {
      await this.transporter.sendMail({
        from: `"MedCare CRM" <${process.env.MAIL_USER}>`,
        to: dto.to,
        subject: `📅 Прийом перенесено — ${dto.date} о ${dto.time}`,
        html,
      });
      this.logger.log(`Update notification sent to ${dto.to}`);
    } catch (err) {
      this.logger.warn(`Failed to send update to ${dto.to}: ${err.message}`);
    }
  }
}
