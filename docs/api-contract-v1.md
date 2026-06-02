# Petji Backend API Contract V1

Petji V1 is local-first. This contract documents the future REST JSON boundary so the Flutter app can later swap local repositories for remote repositories without changing presentation code.

## Shared Rules

- Base path: `/api/v1`
- Content type: `application/json; charset=utf-8`
- IDs: stable UUID strings generated client-side or server-side.
- Sync fields on mutable resources: `id`, `createdAt`, `updatedAt`, `deletedAt`.
- Date/time values: ISO-8601 strings with timezone where available.
- Money: integer cents, never floating point.

## Resources

### Pets

`GET /pets`

```json
{
  "items": [
    {
      "id": "pet-1",
      "name": "Momo",
      "species": "cat",
      "breed": "British Shorthair",
      "birthday": "2024-01-15T00:00:00.000",
      "sex": "female",
      "isNeutered": true,
      "avatarPath": null,
      "notes": "温和，喜欢窗边晒太阳",
      "createdAt": "2026-06-01T00:00:00.000",
      "updatedAt": "2026-06-01T00:00:00.000",
      "deletedAt": null
    }
  ]
}
```

`POST /pets` and `PATCH /pets/{id}` accept the same resource shape.

### Records

`GET /pets/{petId}/records`

Returns health and care records. Weight and feeding can be split into dedicated endpoints later, but the sync shape should stay compatible with the Flutter domain model.

```json
{
  "items": [
    {
      "id": "care-1",
      "petId": "pet-1",
      "category": "bath",
      "happenedAt": "2026-05-10T18:30:00.000",
      "title": "洗澡",
      "note": null,
      "reportPath": null,
      "createdAt": "2026-05-10T18:40:00.000",
      "updatedAt": "2026-05-10T18:40:00.000",
      "deletedAt": null
    }
  ]
}
```

### Reminders

`GET /pets/{petId}/reminders`

```json
{
  "items": [
    {
      "id": "reminder-1",
      "petId": "pet-1",
      "title": "该给Momo洗澡了",
      "dueAt": "2026-06-09T18:30:00.000",
      "status": "scheduled",
      "sourceRecordId": "care-1",
      "createdAt": "2026-05-10T18:45:00.000",
      "updatedAt": "2026-05-10T18:45:00.000",
      "deletedAt": null
    }
  ]
}
```

### Media Metadata

`GET /pets/{petId}/media`

Binary upload will use a separate signed upload endpoint later. The first sync contract stores metadata and a server URL once uploaded.

```json
{
  "items": [
    {
      "id": "media-1",
      "petId": "pet-1",
      "type": "photo",
      "localPath": "app-private-path",
      "remoteUrl": null,
      "capturedAt": "2026-04-22T00:00:00.000",
      "note": "第一次到家",
      "createdAt": "2026-04-22T00:00:00.000",
      "updatedAt": "2026-04-22T00:00:00.000",
      "deletedAt": null
    }
  ]
}
```

### Timeline Events

`GET /pets/{petId}/timeline-events`

Timeline events are the user-facing growth line. They can reference care records, media metadata, or standalone notes.

```json
{
  "items": [
    {
      "id": "timeline-1",
      "petId": "pet-1",
      "type": "vaccine",
      "happenedAt": "2026-06-01T10:00:00.000",
      "title": "年度疫苗",
      "note": "左肩注射",
      "sourceId": "care-1",
      "filePath": null,
      "mediaPath": "media/vaccine.jpg",
      "createdAt": "2026-06-01T10:05:00.000",
      "updatedAt": "2026-06-01T10:05:00.000",
      "deletedAt": null
    }
  ]
}
```

### Todos

`GET /todos?petId=pet-1&status=open`

```json
{
  "items": [
    {
      "id": "todo-1",
      "petId": "pet-1",
      "title": "预约疫苗",
      "status": "open",
      "dueAt": "2026-06-05T00:00:00.000",
      "note": "上午联系医院",
      "completedAt": null,
      "createdAt": "2026-06-01T08:00:00.000",
      "updatedAt": "2026-06-01T08:00:00.000",
      "deletedAt": null
    }
  ]
}
```

### Expenses

`GET /expenses?year=2026&month=6`

```json
{
  "items": [
    {
      "id": "expense-1",
      "petId": "pet-1",
      "category": "food",
      "amountCents": 12990,
      "spentAt": "2026-06-01T00:00:00.000",
      "title": "猫粮",
      "merchant": null,
      "note": null,
      "createdAt": "2026-06-01T00:00:00.000",
      "updatedAt": "2026-06-01T00:00:00.000",
      "deletedAt": null
    }
  ]
}
```

### Sync Batch

`POST /sync/batch`

```json
{
  "clientId": "android-device-id",
  "since": "2026-06-01T00:00:00.000Z",
  "changes": {
    "pets": [],
    "records": [],
    "reminders": [],
    "mediaAssets": [],
    "timelineEvents": [],
    "todos": [],
    "expenses": []
  }
}
```

The server returns accepted changes plus remote changes since `since`. Conflict policy is last-write-wins for V1 cloud sync unless a later product requirement needs field-level conflict resolution.
