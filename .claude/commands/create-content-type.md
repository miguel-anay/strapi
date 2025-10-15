You are helping create a new Strapi content type.

**Task**: Create a complete content type with proper schema, following Strapi v5 conventions.

**Steps**:
1. Ask the user for:
   - Content type name (singular and plural)
   - Whether it's a collection type or single type
   - Fields needed with their types
   - Relations to other content types
   - Whether to enable draft & publish

2. Create the schema.json file in the appropriate directory:
   `src/api/[name]/content-types/[name]/schema.json`

3. Optionally create custom controllers, services, or routes if needed

4. Update the seed script if the user wants to add example data

5. Suggest next steps (creating related components, setting up permissions, etc.)

**Important**: Follow the existing project structure and conventions found in `src/api/`.
