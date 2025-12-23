export default class Reservation {
  reservation_id: number;
  user_id: number;
  facility_id: number;
  start_time: number;
  end_time: number;
  status: string;
  created_at: string;
  // 额外字段，用于UI显示
  facility_name?: string;

  constructor(reservation_id: number, user_id: number, facility_id: number, start_time: number, end_time: number, status: string, created_at: string, facility_name?: string) {
    this.reservation_id = reservation_id;
    this.user_id = user_id;
    this.facility_id = facility_id;
    this.start_time = start_time;
    this.end_time = end_time;
    this.status = status;
    this.created_at = created_at;
    this.facility_name = facility_name;
  }
}
