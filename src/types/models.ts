export type ThemeMode = 'light' | 'dark' | 'amoled';

export type Note = {
  id: string;
  title: string;
  content: string;
  folderId: string | null;
  isPinned: boolean;
  isFavorite: boolean;
  isDeleted: boolean;
  createdAt: string;
  updatedAt: string;
};

export type Folder = {
  id: string;
  name: string;
  sortOrder: number;
  createdAt: string;
  updatedAt: string;
};
