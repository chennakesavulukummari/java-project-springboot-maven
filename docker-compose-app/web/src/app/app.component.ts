import { Component, OnInit } from '@angular/core';
import { HttpClient } from '@angular/common/http';

interface User {
  id: number;
  name: string;
  email: string;
}

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})
export class AppComponent implements OnInit {
  title = 'Docker Compose Full Stack App';
  users: User[] = [];
  newUser = { name: '', email: '' };
  apiUrl = '/api';

  constructor(private http: HttpClient) {}

  ngOnInit() {
    this.loadUsers();
  }

  loadUsers() {
    this.http.get<User[]>(`${this.apiUrl}/users`).subscribe({
      next: (data) => {
        this.users = data;
      },
      error: (error) => {
        console.error('Error loading users:', error);
      }
    });
  }

  addUser() {
    if (this.newUser.name && this.newUser.email) {
      this.http.post<User>(`${this.apiUrl}/users`, this.newUser).subscribe({
        next: (user) => {
          this.users.push(user);
          this.newUser = { name: '', email: '' };
        },
        error: (error) => {
          console.error('Error adding user:', error);
        }
      });
    }
  }

  deleteUser(id: number) {
    this.http.delete(`${this.apiUrl}/users/${id}`).subscribe({
      next: () => {
        this.users = this.users.filter(u => u.id !== id);
      },
      error: (error) => {
        console.error('Error deleting user:', error);
      }
    });
  }
}
