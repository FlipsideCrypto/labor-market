const fs = require('fs')

async function getJSONFiles() {
    let json = []
    const promise = new Promise((resolve, reject) => {
        fs.readdir('./abis', (err, files) => {
            if (err)
                reject(err)
            else {
                json = files.filter((file) => file.endsWith('.json'))
                resolve(json)
            }
        })
    })

    return await promise;
}

function insertString(str, index, value) {
    return str.substr(0, index) + value + str.substr(index);
}

async function main() {
    const files = await getJSONFiles();
    for (var idx in files) {
        const file = files[idx]
        fs.readFile(`abis/${file}`, 'utf-8', function(err, data) {
            if (err)
                throw (err);
            else {
                data = insertString(data, 0, "export const abi = ")
                data = insertString(data, data.length - 1, " as const")
                // rename as ts file
                const fileName = file.replace('.json', '.ts')
                fs.writeFile(`abis/${fileName}`, data, 'utf-8', function(err) {
                    if (err)
                        throw (err);
                })
            }
        })
    }
}

main()