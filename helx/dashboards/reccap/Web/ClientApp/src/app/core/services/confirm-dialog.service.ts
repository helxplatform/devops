import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root',
})
export class ConfirmDialogService {
  constructor() {}

  public confirm(message: string): Promise<boolean> {
    return new Promise((resolve, reject) => {
      resolve(confirm(message));
    });
  }
}
