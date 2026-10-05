# Roblox Studio DataStore access

Roblox documents that Studio access to data stores is disabled by default and requires publishing the experience and enabling **Enable Studio Access to API Services** in Experience Settings > Security. An unpublished place can therefore fail when requesting a named store at startup. Startup code should treat store acquisition as fallible; this project uses an in-memory profile only in Studio when acquisition fails.

Sources:
- https://create.roblox.com/docs/tutorials/use-case-tutorials/data-storage/create-leaderboard#enable-studio-access-to-api-services
- https://create.roblox.com/docs/reference/engine/classes/DataStoreService/GetDataStore
