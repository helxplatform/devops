import { Injectable } from '@angular/core';
import { Subject } from 'rxjs';
import { Route } from '@angular/router';

export class PreloadOnDemandOptions {
  constructor(public preloadId: string, public preload = true) {}
}

@Injectable({
  providedIn: 'root',
})
export class PreloadOnDemandService {
  private subject = new Subject<PreloadOnDemandOptions>();
  state = this.subject.asObservable();

  startPreload(preloadId: string): void {
    const message = new PreloadOnDemandOptions(preloadId, true);
    this.subject.next(message);
  }
}
