export default class Facility {
  facility_id: number | null = null;
  facility_name: string | null = null;
  facility_type: string | null = null;
  description: string | null = null;
  location: string | null = null;
  capacity: number | null = null;
  image: string | null = null;
  created_at: string | null = null;

  constructor(facility_id: number, facility_name: string, facility_type: string, description: string, location: string, capacity: number, image: string, created_at: string) {
    this.facility_id = facility_id;
    this.facility_name = facility_name;
    this.facility_type = facility_type;
    this.description = description;
    this.location = location;
    this.capacity = capacity;
    this.image = image;
    this.created_at = created_at;
  }
}
