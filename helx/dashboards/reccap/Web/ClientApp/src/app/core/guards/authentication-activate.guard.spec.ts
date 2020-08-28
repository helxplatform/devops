import { TestBed } from '@angular/core/testing';

import { AuthenticationActivateGuard } from './authentication-activate.guard';

describe('AuthenticationActivateGuard', () => {
  let guard: AuthenticationActivateGuard;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    guard = TestBed.inject(AuthenticationActivateGuard);
  });

  it('should be created', () => {
    expect(guard).toBeTruthy();
  });
});
