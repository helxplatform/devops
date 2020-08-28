export declare type SearchParams = {
  [key: string]: string;
};

type ReadErrorMessage = (name?: any) => string;

export declare type ValidationMessages = {
  [key: string]: ReadErrorMessage;
};
