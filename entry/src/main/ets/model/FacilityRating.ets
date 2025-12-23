export default class FacilityRating {
  rating_id: number;
  user_id: number;
  facility_id: number;
  score: number;
  comment: string;
  created_at: string;
  // 额外字段
  username?: string;
  full_name?: string;
  facility_name?: string;

  constructor(rating_id: number, user_id: number, facility_id: number, score: number, comment: string, created_at: string, username?: string, full_name?: string, facility_name?: string) {
    this.rating_id = rating_id;
    this.user_id = user_id;
    this.facility_id = facility_id;
    this.score = score;
    this.comment = comment;
    this.created_at = created_at;
    this.username = username;
    this.full_name = full_name;
    this.facility_name = facility_name;
  }
}
