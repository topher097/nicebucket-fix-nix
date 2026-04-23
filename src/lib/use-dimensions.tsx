import { useEffect, useRef, useState } from "react";

export interface ElementDimensions {
  width: number;
  height: number;
}

export function useDimensions<T extends HTMLElement>({
  onResize,
}: {
  onResize?: (dimensions: ElementDimensions) => void;
} = {}) {
  const ref = useRef<T>(null);
  const [dimensions, setDimensions] = useState({ width: 0, height: 0 });
  const previousHeightRef = useRef<number>(0);

  useEffect(() => {
    const element = ref.current;

    if (!element) {
      return;
    }

    const observer = new ResizeObserver(([entry]) => {
      const nextDimensions = entry?.contentRect ?? { width: 0, height: 0 };
      setDimensions(nextDimensions);

      if (previousHeightRef.current === nextDimensions.height) {
        return;
      }

      previousHeightRef.current = nextDimensions.height;
      onResize?.(nextDimensions);
    });

    observer.observe(element);

    return () => {
      observer.disconnect();
    };
  }, [onResize]);

  return { ref, dimensions };
}
