import { Injectable } from '@angular/core';
import { Router, NavigationStart } from '@angular/router';
import { Subject, Observable } from 'rxjs';

export class Notification {
  constructor(
    public id: number,
    public type: NotificationType,
    public title: string | null,
    public message: string,
    public timeout: number,
  ) {}
}

export enum NotificationType {
  success = 0,
  warning = 1,
  error = 2,
  info = 3,
}

@Injectable({
  providedIn: 'root',
})
export class NotificationService {
  private subject = new Subject<Notification[]>();
  private idx = 0;

  notifications: Notification[] = [];

  get notificationsChanged(): Observable<Notification[]> {
    return this.subject.asObservable();
  }

  constructor(router: Router) {
    router.events.subscribe((e) => {
      if (e instanceof NavigationStart) {
        // When navigation starts remove notification without timeout
        this.notifications = this.notifications.filter((n) => !!n.timeout);
        this.subject.next(this.notifications);
      }
    });
  }

  info(message: string, title: string | null = null, timeout = 5000): void {
    const notification = new Notification(this.idx++, NotificationType.info, title, message, timeout);
    this.addNotification(notification);
  }

  success(message: string, title: string | null = null, timeout = 5000): void {
    const notification = new Notification(this.idx++, NotificationType.success, title, message, timeout);
    this.addNotification(notification);
  }

  warning(message: string, title: string | null = null, timeout = 0): void {
    const notification = new Notification(this.idx++, NotificationType.warning, title, message, timeout);
    this.addNotification(notification);
  }

  error(message: string, title: string | null = null, timeout = 0): void {
    const notification = new Notification(this.idx++, NotificationType.error, title, message, timeout);
    this.addNotification(notification);
  }

  close(notification: Notification): void {
    this.notifications = this.notifications.filter((n) => n.id !== notification.id);
    this.subject.next(this.notifications);
  }

  private addNotification(notification: Notification): void {
    if (!this.notifications.some((m) => m.message === notification.message && m.title === notification.title)) {
      this.notifications.push(notification);
      if (notification.timeout !== 0) {
        setTimeout(() => this.close(notification), notification.timeout);
      }
      this.subject.next(this.notifications);
    }
  }
}
