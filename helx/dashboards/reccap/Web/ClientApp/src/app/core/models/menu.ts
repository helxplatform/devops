export interface BadgeItem {
  type: 'success' | 'warning' | 'error';
  value: string;
}
export interface Separator {
  name: string;
  type?: string;
}
export interface ChildrenItem {
  url: string;
  preloadId?: string;
  name: string;
  permissions?: Array<number>;
  type?: string;
  children?: ChildrenItem[];
  loadChildren?: (data: any) => ChildrenItem[];
  expanded?: boolean;
  selected?: boolean;
}

export interface Menu {
  url: string;
  preloadId?: string;
  name: string;
  permissions?: Array<number>;
  type: string;
  icon: string;
  badge?: BadgeItem[];
  saperator?: Separator[];
  children?: ChildrenItem[];
  loadChildren?: (data: any) => ChildrenItem[];
  expanded?: boolean;
  selected?: boolean;
}
