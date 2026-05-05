import { Controller, Get, Post, Param, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { LabTestsService } from './lab-tests.service';
import { CreateLabTestDto } from './dto/create-lab-test.dto';

@ApiTags('lab-tests')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('lab-tests')
export class LabTestsController {
  constructor(private service: LabTestsService) {}

  @Get('patient/:patientId')
  @ApiOperation({ summary: 'GET /lab-tests/patient/:id — аналізи пацієнта' })
  findByPatient(@Param('patientId') patientId: string) {
    return this.service.findByPatient(patientId);
  }

  @Post()
  @ApiOperation({ summary: 'POST /lab-tests — створити аналіз' })
  create(@Body() dto: CreateLabTestDto) {
    return this.service.create(dto);
  }
}
