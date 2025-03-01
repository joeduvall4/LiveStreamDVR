import { Config } from "@/Core/Config";
import chalk from "chalk";
import { formatBytes } from "./Format";

export function progressOutput(text: string) {
    if (Config.debug) {
        const mem = process.memoryUsage();
        console.log(
            chalk.bgGreen.whiteBright(`${text} [${formatBytes(mem.heapUsed)}/${formatBytes(mem.heapTotal)}]`)
        );
    } else {
        console.log(
            chalk.bgGreen.whiteBright(text)
        );
    }
}

export function debugLog(...args: any[]) {
    if (Config && Config.debug) {
        console.debug(
            chalk.redBright(`[debug/${new Date().toISOString()}]`),
            ...args
        );
    }
}