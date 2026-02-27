import { useEffect, useRef, useState } from "react";

export interface ElementDimensions {
  width: number;
  height: number;
}

export function useDimensions<T extends HTMLElement>(props?: {
  onResize: (dimensions: ElementDimensions) => void;
}) {
  const ref = useRef<T>(null);
  const [dimensions, setDimensions] = useState({ width: 0, height: 0 });
  const previousHeightRef = useRef<number>(0);

  useEffect(() => {
    const observer = new ResizeObserver(([entry]) => {
      const _dimensions = entry?.contentRect ?? { width: 0, height: 0 };
      setDimensions(_dimensions);

      if (previousHeightRef.current !== _dimensions.height) {
        previousHeightRef.current = _dimensions.height;
        props?.onResize(_dimensions);
      }
    });

    if (ref.current) {
      observer.observe(ref.current);
    }

    return () => {
      if (ref.current) {
        observer.unobserve(ref.current);
      }
    };
  }, []);

  return { ref, dimensions };
}
