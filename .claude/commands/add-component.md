You are helping create a new shared component for Strapi.

**Task**: Create a reusable component that can be used in content types.

**Steps**:
1. Ask the user for:
   - Component name
   - Component category (e.g., "shared", "sections", "elements")
   - Fields needed with their types
   - Icon name (optional)
   - Description

2. Create the component JSON file:
   `src/components/[category]/[name].json`

3. Show how to use it in content types:
   - As a single component field
   - In a repeatable component field
   - In a dynamic zone

4. Suggest related components if applicable

**Example component structure**:
```json
{
  "collectionName": "components_[category]_[name]",
  "info": {
    "displayName": "Component Name",
    "icon": "icon-name",
    "description": "Description"
  },
  "options": {},
  "attributes": {
    // Fields here
  }
}
```

**Important**: Follow the existing component structure in `src/components/shared/`.
