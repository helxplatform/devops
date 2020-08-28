import { TestBed } from '@angular/core/testing';

import { PreloadOnDemandService } from './preload-ondemand.service';

describe('PreloadOnDemandService', () => {
  let service: PreloadOnDemandService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(PreloadOnDemandService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
