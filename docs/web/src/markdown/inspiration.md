# Inspiration

We credit for very few of the concepts in Riptide. Designing it was a process of discovering good ideas in other projects and combining them in a way we found useful. We'd like to acknowledge these projects here.

***

## (The Original) Firebase

Modeling all of your data as one big tree and sortable UUIDs prefixed with time are concepts pulled from Firebase.  They validated this approach and provided guidance on best practices when using this type of data structure.

Firebase was acquired by Google and looks very different now but [some of the original concepts survived](https://firebase.google.com/docs/database/web/structure-data)

***

## PouchDB

PouchDB introduced us to the idea that there is no difference between clients and servers.  You can treat them both as nodes in a cluster that sync different subsets of the overall dataset. Much of Riptide's client APIs were designed by studying PouchDB.

[PouchDB Documentation](https://pouchdb.com/)

***

## Tailwind

If this documentation site looks familiar it's because we borrowed the design + structure from the open source Tailwind docs.  Seeing their flawless execution on documentation is what initially inspired us to get our act together and document Riptide properly.

[Tailwind Documentation](https://tailwindcss.com/)