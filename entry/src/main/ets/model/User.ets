export default class User {
  user_id: number | null = null;
  username: string | null = null;
  password_hash: string | null = null;
  full_name: string | null = null;
  phone: string | null = null;
  email: string | null = null;
  created_at: string | null = null;

  constructor(user_id: number, username: string, password_hash: string, full_name: string, phone: string, email: string, created_at: string) {
    this.user_id = user_id;
    this.username = username;
    this.password_hash = password_hash;
    this.full_name = full_name;
    this.phone = phone;
    this.email = email;
    this.created_at = created_at;
  }
}
