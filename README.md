**MochaCDN** is a mixed, rapid, global content delivery network.

# URL
```
ajax.mochacdn.com
```

# Parameters

## Mix (JS, CSS)
List of packages to mix

```
/(js|css)?mix=package1,package2,package3
```

You can also use above pattern:
```
/(js|css)?mix=package1@1.0.0,package2/path/to/file,package3
```
- We'll do our best to find main file.
- No need to use file extention (.js|.css).

---

## Env (Enviroment)
### Production: (`default`)
- Minify: true
```
&env=production
```
### Development:
- Minify: false
```
&env=development
```

# Usage

## NPM
### Pattern:
```
/npm/package@version/path/to/file
```
### Examples:
- Normal:
https://ajax.mochacdn.com/npm/jquery/dist/jquery.js

- Mix Javascript:
https://ajax.mochacdn.com/npm/js?mix=bootstrap,aos
- Mix Stylesheet:
https://ajax.mochacdn.com/npm/css?mix=bootstrap,aos