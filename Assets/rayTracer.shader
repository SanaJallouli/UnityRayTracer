Shader "Custom/rayTracer" {
  SubShader {
    Pass {
      CGPROGRAM

#pragma target 3.0

      sampler2D _MainTex;

      struct Ray {
        float3 origin;
        float3 direction;

        float3 at(float t) { return origin + direction * t; }
      };

      struct material

      {
        float specularProbability;
        float4 color;
        float4 emissionColor;
        float4 specularColor;
        float emissionStrength;
        float refractivity;
        float reflectivity;
        float diffuse;
        float refractiveIndex;
        float smoothness;
      };

      struct Sphere {
        float3 position;
        float radius;
        material mat;
      };

      StructuredBuffer<Sphere> Spheres;
      int NumSpheres;

      struct hit_record {
        bool hit;
        float3 p;
        float3 normal;
        float t;
        bool front_face;
        material mat;

        void set_face_normal(Ray r, float3 outward_normal) {
          front_face = dot(r.direction, outward_normal) < 0;
          normal = front_face ? outward_normal : -outward_normal;
        }
      };

      hit_record hit_sphere(Sphere s, Ray r, float ray_tmin, float ray_tmax) {
        float3 position = s.position;
        float radius = s.radius;

        float a = dot(r.direction, r.direction);
        float b = dot(2 * r.direction, r.origin - position);
        float c =
            dot((r.origin - position), (r.origin - position)) - radius * radius;

        float delta = b * b - 4 * a * c;
        hit_record rec;

        if (delta < 0.0f) {
          rec.hit = false;
          return rec;
        }

        if (delta == 0.0f) {
          float t = -b / (2.0 * a);
          if (t <= ray_tmin || ray_tmax <= t) {
            rec.hit = false;
            return rec;
          }
          rec.t = t;
          rec.p = r.at(rec.t);
          rec.normal = normalize(rec.p - position);
          rec.mat = s.mat;
          rec.hit = true;
          return rec;
        }

        if (delta > 0.0f) {
          float t = (-b - sqrt(delta)) / (2.0f * a);

          if (t <= ray_tmin || ray_tmax <= t)
            t = (-b + sqrt(delta)) / (2.0f * a);
          if (t <= ray_tmin || ray_tmax <= t) {
            rec.hit = false;
            return rec;
          }

          rec.t = t;
          rec.p = r.at(rec.t);
          float3 outward = normalize(rec.p - position);
          rec.set_face_normal(r, outward);
          rec.hit = true;
          rec.mat = s.mat;
          return rec;
        }

        rec.hit = false;
        return rec;
      }
      // throw the ray and find the closest hit :
      // find all the hits and return the hit record with the smallest t (the
      // closest point along the ray where there was a hit)
      hit_record hit(Ray r, float ray_tmin, float ray_tmax) {
        // ray_tmax : furtherest point along the ray, for which we will consider
        // the hit.
        hit_record to_return;
        to_return.t = ray_tmax;  // start by this then see if we have a hit that
                                 // is closer to the camera ;
        for (int i = 0; i < NumSpheres; i++) {
          hit_record temp_record;
          temp_record = hit_sphere(Spheres[i], r, ray_tmin, ray_tmax);
          if (temp_record.hit) {
            if (temp_record.t < to_return.t) {
              to_return = temp_record;
            }
          }
        }
        return to_return;
      };

      float3 refract(float3 incident, float3 normal, float eta) {
        float NdotI = dot(normal, incident);
        float k = 1.0 - eta * eta * (1.0 - NdotI * NdotI);

        if (k < 0.0) {
          return float3(0.0, 0.0, 0.0);  // Total internal reflection
        } else {
          return eta * incident - (eta * NdotI + sqrt(k)) * normal;
        }
      }

      float RandomFloat() {
        return frac(sin(_Time.y * 12.9898 + _Time.x * 78.233) * 43758.5453);
      }

      // Function to generate a random float in a specific range [min, max)
      float RandomFloatInRange(float min, float max) {
        return min + RandomFloat() * (max - min);
      }

      float3 random_unit_in_unit_sphere() {
        fixed3 temp = float3(0.1, 0.1, 0.1f);
        while (true) {
          temp = float3(RandomFloatInRange(-1, 1), RandomFloatInRange(-1, 1),
                        RandomFloatInRange(-1, 1));

          if (dot(temp, temp) < 1) {
            return normalize(temp);
          }
        }

        return normalize(temp);
      }
      float3 random_unit_on_hemisphere(fixed3 normal) {
        float3 temp = random_unit_in_unit_sphere();
        if (dot(temp, normal) > 0) return temp;
        return -temp;
      }

      fixed3 random_unit_on_hemisphere_lambertian(fixed3 normal) {
        fixed3 temp =
            random_unit_in_unit_sphere();  // unit so that when added we get the
                                           // direction we want not influenced
                                           // by the length

        if (dot(temp, normal) > 0)
          return temp + normal;  // the normal to surface and the random ray
                                 // look in same direction ;
        return -temp + normal;
      }

      float3 GetEnvironmentLight(Ray ray) {
        fixed3 composite = fixed3(0.2f, 0.2f, 0.2f);
        return composite;
      }

      float4 CameraCenter;
      float4 Camera;

#pragma vertex vert
#pragma fragment frag

      struct appdata {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
      };

      struct v2f {
        float4 vertex : SV_POSITION;
        float2 uv : TEXCOORD0;
      };

      v2f vert(appdata v) {
        v2f o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv = v.uv;
        return o;
      }
      float3 myReflect(float3 normal, float3 r) {
        return normalize(r - (2 * normal * (dot(r, normal))));
      };

      float3 CalculateColor(Ray ray, float ray_tmin, float ray_tmax) {
        float3 incomingLight = 0;
        float3 rayColour = 1;

        for (int bounceIndex = 0; bounceIndex <= 100; bounceIndex++) {
          hit_record rec = hit(ray, ray_tmin, ray_tmax);

          if (rec.hit) {
            material mat = rec.mat;

            bool isSpecularBounce = mat.specularProbability >= RandomFloat();

            ray.origin = rec.p;
            float3 temp = rec.normal + float3(RandomFloatInRange(0, 1),
                                              RandomFloatInRange(0, 1),
                                              RandomFloatInRange(0, 1));
            float3 diffuseDir = normalize(temp);
            float3 specularDir = myReflect(ray.direction, rec.normal);
            ray.direction = normalize(lerp(diffuseDir, specularDir,
                                           mat.smoothness * isSpecularBounce));

            float3 emittedLight = mat.emissionColor * mat.emissionStrength;
            incomingLight += emittedLight * rayColour;
            rayColour *= lerp(mat.color, mat.specularColor, isSpecularBounce);

            float p = max(rayColour.r, max(rayColour.g, rayColour.b));

            rayColour *= 1.0f / p;
          } else {
            incomingLight += GetEnvironmentLight(ray) * rayColour;
            break;
          }
        }

        return incomingLight;
      }

      fixed4 frag(v2f i) : SV_Target {
        Ray ray;
        ray.origin = _WorldSpaceCameraPos;
        float focal_length = _ProjectionParams.y;
        float2 uv_our_world = (i.uv * 2 - 1);
        float3 pixel_pos = float3(uv_our_world.x * Camera.x / Camera.y,
                                  uv_our_world.y, -focal_length);
        ray.direction = normalize(pixel_pos - ray.origin);

        float t_min = 0.001f;
        float t_max = 200.0f;

        fixed3 v = CalculateColor(ray, t_min, t_max);
        return fixed4(v, 1);
      }

      ENDCG
    }
  }
}
