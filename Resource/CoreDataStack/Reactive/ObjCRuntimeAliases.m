#import <objc/runtime.h>
#import <objc/message.h>

void _cds_rac_objc_setAssociatedObject(const void* object, const void* key, id value, objc_AssociationPolicy policy) {
	__unsafe_unretained id obj = (__bridge typeof(obj)) object;
	objc_setAssociatedObject(obj, key, value, policy);
}
