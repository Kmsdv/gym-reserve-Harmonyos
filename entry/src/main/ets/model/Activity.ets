export default class Activity {
  activity_id: number;
  facility_id: number;
  organizer_id: number;
  title: string;
  description: string;
  start_time: string;
  end_time: string;
  status: string;
  created_at: string;
  
  // Optional fields for display
  facility_name?: string;
  organizer_name?: string;
  participant_count?: number;

  constructor(
    activity_id: number,
    facility_id: number,
    organizer_id: number,
    title: string,
    description: string,
    start_time: string,
    end_time: string,
    status: string,
    created_at: string,
    facility_name?: string,
    organizer_name?: string,
    participant_count?: number
  ) {
    this.activity_id = activity_id;
    this.facility_id = facility_id;
    this.organizer_id = organizer_id;
    this.title = title;
    this.description = description;
    this.start_time = start_time;
    this.end_time = end_time;
    this.status = status;
    this.created_at = created_at;
    this.facility_name = facility_name;
    this.organizer_name = organizer_name;
    this.participant_count = participant_count;
  }
}
